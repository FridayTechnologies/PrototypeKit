//
//  ActionClassifierView.swift
//
//
//  Created by James Dale on 2/7/2026.
//

import SwiftUI
import CoreML
import Vision

/// Configuration options for live action classification via ``ActionClassifierView``.
///
/// The defaults match the input and output feature names produced by a standard Create ML
/// **Action Classifier**, which is trained on sequences of human body-pose keypoints. If your model
/// uses different feature names or window size, override them here so they line up with your model.
public struct ActionClassifierConfiguration {

    /// The model input feature name for the window of body-pose keypoints.
    ///
    /// Create ML's Action Classifier names this input `"poses"` and expects a multi-array shaped
    /// `[window, 3, 18]` — one `[1, 3, 18]` slice per frame, as produced by
    /// `VNHumanBodyPoseObservation.keypointsMultiArray()`.
    var posesFeatureName: String

    /// The model output feature name for the predicted action label.
    var labelFeatureName: String

    /// The number of frames of body-pose data that inform a single prediction.
    ///
    /// This should match the model's prediction window. When the model advertises a fixed input
    /// window, ``ActionClassifierView`` uses the model's value; otherwise it falls back to this one.
    /// Create ML's Action Classifier template defaults to a two-second window.
    var predictionWindowSize: Int

    /// How many new frames to collect between predictions once a full window is available.
    ///
    /// Running the model on every frame is wasteful, so predictions are throttled: after the window
    /// fills, a new prediction is made every `predictionInterval` frames while the window slides
    /// forward. A smaller value is more responsive; a larger value is cheaper.
    var predictionInterval: Int

    /// Creates an action classifier configuration.
    ///
    /// - Parameters:
    ///   - posesFeatureName: The body-pose window input feature name. Defaults to `"poses"`.
    ///   - labelFeatureName: The predicted label output feature name. Defaults to `"label"`.
    ///   - predictionWindowSize: The number of frames per prediction. Used only when the model does
    ///     not advertise a fixed input window. Defaults to `60` (two seconds at 30 fps).
    ///   - predictionInterval: The number of new frames between predictions once the window is full.
    ///     Defaults to `15`.
    public init(posesFeatureName: String = "poses",
                labelFeatureName: String = "label",
                predictionWindowSize: Int = 60,
                predictionInterval: Int = 15) {
        self.posesFeatureName = posesFeatureName
        self.labelFeatureName = labelFeatureName
        self.predictionWindowSize = predictionWindowSize
        self.predictionInterval = predictionInterval
    }
}

final class ActionClassifierReceiver: PKCameraViewReceiver, ObservableObject {

    private let mlModel: MLModel?
    private let configuration: ActionClassifierConfiguration

    @Published var latestPrediction: String?

    /// The number of frames that make up one prediction window.
    private let windowSize: Int

    /// A rolling buffer of per-frame body-pose keypoint arrays, each shaped `[1, 3, 18]`.
    private var poseWindow: [MLMultiArray] = []

    /// How many frames have been collected since the last prediction was made.
    private var framesSinceLastPrediction = 0

    private lazy var bodyPoseRequest: VNDetectHumanBodyPoseRequest? = {
        guard self.mlModel != nil else { return nil }
        return VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                PKLog.vision.error("Body pose request failed: \(error.localizedDescription)")
                return
            }

            // Take the most prominent person in the frame. When nobody is detected we still advance
            // the window with a zero-filled slice, matching how Create ML pads missing frames — so a
            // person leaving and re-entering the frame doesn't corrupt the temporal window.
            let observation = (request.results as? [VNHumanBodyPoseObservation])?.first
            let pose = (try? observation?.keypointsMultiArray()) ?? self.emptyPose()
            guard let pose = pose else { return }

            self.append(pose)
        }
    }()

    /// Creates a receiver for the given action model.
    ///
    /// - Parameters:
    ///   - mlModel: The Core ML action-classification model, or `nil` when the model failed to load.
    ///     When `nil`, frames are ignored and no predictions are published.
    ///   - configuration: The window and feature-name configuration.
    init(mlModel: MLModel?, configuration: ActionClassifierConfiguration) {
        self.mlModel = mlModel
        self.configuration = configuration

        // Prefer the model's own window size when it advertises one, so the buffer always matches.
        let inputs = mlModel?.modelDescription.inputDescriptionsByName ?? [:]
        let modelWindow = inputs[configuration.posesFeatureName]?
            .multiArrayConstraint?.shape.first?.intValue
        if let modelWindow = modelWindow, modelWindow > 0 {
            self.windowSize = modelWindow
        } else {
            self.windowSize = configuration.predictionWindowSize
        }
    }

    func processImage(_ cgImage: CGImage) {
        guard let bodyPoseRequest = bodyPoseRequest else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])

        do {
            try handler.perform([bodyPoseRequest])
        } catch {
            PKLog.vision.error("Failed to perform body pose detection: \(error.localizedDescription)")
        }
    }

    /// A zero-filled `[1, 3, 18]` keypoint slice, used to pad frames where no body is detected.
    private func emptyPose() -> MLMultiArray? {
        guard let pose = try? MLMultiArray(shape: [1, 3, 18], dataType: .float32) else { return nil }
        for i in 0..<pose.count { pose[i] = 0 }
        return pose
    }

    /// Adds a frame's keypoints to the rolling window and predicts once enough frames have arrived.
    private func append(_ pose: MLMultiArray) {
        poseWindow.append(pose)
        if poseWindow.count > windowSize {
            poseWindow.removeFirst(poseWindow.count - windowSize)
        }

        framesSinceLastPrediction += 1
        if poseWindow.count == windowSize && framesSinceLastPrediction >= configuration.predictionInterval {
            framesSinceLastPrediction = 0
            predict()
        }
    }

    /// Runs the model over the current window and publishes the predicted label.
    private func predict() {
        guard let mlModel = mlModel else { return }
        guard let modelInput = try? MLMultiArray(concatenating: poseWindow, axis: 0, dataType: .float32) else {
            return
        }

        guard
            let featureProvider = try? MLDictionaryFeatureProvider(dictionary: [
                configuration.posesFeatureName: modelInput
            ]),
            let prediction = try? mlModel.prediction(from: featureProvider)
        else { return }

        if let label = prediction.featureValue(for: configuration.labelFeatureName)?.stringValue {
            DispatchQueue.main.async {
                self.latestPrediction = label
            }
        }
    }
}

/// A SwiftUI view that shows a live camera feed and classifies a person's action from their body
/// movement using a Core ML model.
///
/// The view detects human body-pose keypoints with Vision's `VNDetectHumanBodyPoseRequest` and feeds a
/// sliding window of them into the Create ML / Core ML **Action Classifier** you provide, publishing the
/// predicted label through a binding. Because an action unfolds over time, the view collects a window of
/// frames (two seconds by default) before its first prediction and updates as the window slides forward.
///
/// It drives a ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var latestPrediction = ""
///
/// ActionClassifierView(modelURL: JumpingJacksClassifier.urlOfModelInThisBundle,
///                      latestPrediction: $latestPrediction)
/// ```
///
/// - Note: The most prominent person in the frame is classified; frames without a detected body are
///   padded so a person briefly leaving the frame doesn't corrupt the window.
public struct ActionClassifierView: View {

    @State var receiver: ActionClassifierReceiver

    @Binding var latestPrediction: String

    private let cameraOptions: CameraOptions?

    private let onError: ((PrototypeKitError) -> Void)?

    private let loadError: PrototypeKitError?

    /// Creates an action classifier view backed by a Core ML model.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML action-classification model to
    ///     load, typically `YourModel.urlOfModelInThisBundle`.
    ///   - configuration: An ``ActionClassifierConfiguration`` describing the prediction window and the
    ///     model's feature names. Defaults match a standard Create ML Action Classifier.
    ///   - latestPrediction: A binding updated with the most recent predicted action label. Defaults to a
    ///     constant empty string when you only need the on-screen camera feed.
    ///   - camera: Optional ``CameraOptions`` selecting the camera position and device type. Pass `nil`
    ///     to use the default back wide-angle camera. (Ignored on macOS.)
    ///   - onError: An optional closure called (on the main thread) if the model fails to load. The view
    ///     still shows the camera feed without classification; use this to surface the failure in your UI.
    public init(modelURL: URL,
                configuration: ActionClassifierConfiguration = .init(),
                latestPrediction: Binding<String> = .constant(""),
                camera: CameraOptions? = nil,
                onError: ((PrototypeKitError) -> Void)? = nil) {
        self._latestPrediction = latestPrediction
        self.cameraOptions = camera
        self.onError = onError
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            self.receiver = ActionClassifierReceiver(mlModel: mlModel, configuration: configuration)
            self.loadError = nil
        } catch {
            // Degrade gracefully: show the camera feed without classification rather than
            // crashing the host app when the model can't be loaded.
            PKLog.model.error("Failed to load action model at \(modelURL.path): \(error.localizedDescription)")
            self.receiver = ActionClassifierReceiver(mlModel: nil, configuration: configuration)
            self.loadError = .modelLoadFailed(url: modelURL, underlying: error)
        }
    }

    public var body: some View {
        PKCameraView(receiver: receiver, options: cameraOptions)
            .onReceive(receiver.$latestPrediction, perform: { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestPrediction = newPrediction
            })
            .onAppear {
                if let loadError = loadError { onError?(loadError) }
            }
    }
}
