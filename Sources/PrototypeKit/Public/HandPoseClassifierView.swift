//
//  HandPoseClassifierView.swift
//
//
//  Created by James Dale on 5/6/2024.
//

import SwiftUI
import CoreML
import Vision

final class HandPoseClassifierReceiver: PKCameraViewReceiver, ObservableObject {

    private let mlModel: MLModel?

    @Published var latestPrediction: String?

    private lazy var handPoseRequest: VNDetectHumanHandPoseRequest? = {
        guard let model = self.mlModel else { return nil }
        let req = VNDetectHumanHandPoseRequest { [weak self] request, error in
            if let error = error {
                PKLog.vision.error("Hand pose request failed: \(error.localizedDescription)")
                return
            }
            guard
                let handRequest = request as? VNDetectHumanHandPoseRequest,
                let handposes = handRequest.results,
                let handObservation = handposes.first,
                let multiArray = try? handObservation.keypointsMultiArray(),
                let fp = try? MLDictionaryFeatureProvider(dictionary: [
                    "poses": multiArray
                ]),
                let prediction = try? model.prediction(from: fp)
            else { return }

            if let label = prediction.featureValue(for: "label") {
                DispatchQueue.main.async {
                    self?.latestPrediction = label.stringValue
                }
            }

        }
        req.revision = 1
        req.maximumHandCount = 1
        return req
    }()

    /// Creates a receiver for the given hand-pose model.
    ///
    /// - Parameter mlModel: The Core ML hand-pose classification model, or `nil` when the model failed
    ///   to load. When `nil`, frames are ignored and no predictions are published.
    init(mlModel: MLModel?) {
        self.mlModel = mlModel
    }

    func processImage(_ cgImage: CGImage) {
        guard let handPoseRequest = handPoseRequest else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])

#if targetEnvironment(simulator)
        // Running in simulator
        handPoseRequest.usesCPUOnly = true
#endif

#if canImport(XCTest)
        // Running in XCTest
        handPoseRequest.usesCPUOnly = true
#endif

        do {
            try handler.perform([handPoseRequest])
        } catch {
            PKLog.vision.error("Failed to perform hand pose detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and classifies hand poses using a Core ML model.
///
/// The view detects hand keypoints with Vision's `VNDetectHumanHandPoseRequest` and feeds them into the
/// Create ML / Core ML hand-action classifier you provide, publishing the predicted label through a binding.
/// It drives a ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var latestPrediction = ""
///
/// HandPoseClassifierView(modelURL: HandPoseClassifier.urlOfModelInThisBundle,
///                        latestPrediction: $latestPrediction)
/// ```
///
/// - Note: A single hand is classified at a time (`maximumHandCount = 1`).
public struct HandPoseClassifierView: View {

    @State var receiver: HandPoseClassifierReceiver

    @Binding var latestPrediction: String

    /// Creates a hand pose classifier view backed by a Core ML model.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML hand-pose model to load, typically
    ///     `YourModel.urlOfModelInThisBundle`.
    ///   - latestPrediction: A binding updated with the most recent predicted hand-pose label. Defaults to a
    ///     constant empty string when you only need the on-screen camera feed.
    public init(modelURL: URL, latestPrediction: Binding<String> = .constant("")) {
        self._latestPrediction = latestPrediction
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            self.receiver = HandPoseClassifierReceiver(mlModel: mlModel)
        } catch {
            // Degrade gracefully: show the camera feed without classification rather than
            // crashing the host app when the model can't be loaded.
            PKLog.model.error("Failed to load hand pose model at \(modelURL.path): \(error.localizedDescription)")
            self.receiver = HandPoseClassifierReceiver(mlModel: nil)
        }
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$latestPrediction, perform: { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestPrediction = newPrediction
            })
    }
}
