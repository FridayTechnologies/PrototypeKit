//
//  ImageClassifierView.swift
//
//
//  Created by James Dale on 1/2/2024.
//

import SwiftUI
import CoreML
import Vision

final class ImageClassifierReceiver: PKCameraViewReceiver, ObservableObject {

    private let vnCoreMLModel: VNCoreMLModel?

    @Published var latestPrediction: String?

    private lazy var request: VNCoreMLRequest? = {
        guard let model = self.vnCoreMLModel else { return nil }
        return VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                PKLog.vision.error("Image classification request failed: \(error.localizedDescription)")
                return
            }
            guard let observation = request.results?.first as? VNClassificationObservation else {
                return
            }
            DispatchQueue.main.async {
                self?.latestPrediction = observation.identifier
            }
        }
    }()

    /// Creates a receiver for the given Vision model.
    ///
    /// - Parameter vnMLModel: The Vision Core ML model to classify frames with, or `nil` when the model
    ///   failed to load. When `nil`, frames are ignored and no predictions are published.
    init(vnMLModel: VNCoreMLModel?) {
        self.vnCoreMLModel = vnMLModel
    }

    func processImage(_ cgImage: CGImage) {
        guard let request = request else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])

#if targetEnvironment(simulator)
        // Running in simulator
        request.usesCPUOnly = true
#endif

#if canImport(XCTest)
        // Running in XCTest
        request.usesCPUOnly = true
#endif
        request.imageCropAndScaleOption = .centerCrop
        do {
            try handler.perform([request])
        } catch {
            PKLog.vision.error("Failed to perform image classification: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and classifies each frame using a Core ML image classifier.
///
/// Provide the URL of a Create ML / Core ML image-classification model and a binding to receive the
/// most recent predicted label. The view drives a ``PKCameraView`` internally, so your app target must
/// declare the `NSCameraUsageDescription` (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var latestPrediction = ""
///
/// ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle,
///                     latestPrediction: $latestPrediction)
/// ```
///
/// - Note: The classifier emits the top label only; confidence scores are not surfaced.
public struct ImageClassifierView: View {

    @State var receiver: ImageClassifierReceiver

    @Binding var latestPrediction: String

    private let cameraOptions: CameraOptions?

    /// Creates an image classifier view backed by a Core ML model.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML model to load, typically
    ///     `YourModel.urlOfModelInThisBundle`.
    ///   - latestPrediction: A binding updated with the most recent top-label prediction. Defaults to a
    ///     constant empty string when you only need the on-screen camera feed.
    ///   - camera: Optional ``CameraOptions`` selecting the camera position and device type. Pass `nil`
    ///     to use the default back wide-angle camera. (Ignored on macOS.)
    public init(modelURL: URL,
                latestPrediction: Binding<String> = .constant(""),
                camera: CameraOptions? = nil) {
        self._latestPrediction = latestPrediction
        self.cameraOptions = camera
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let vnModel = try VNCoreMLModel(for: mlModel)
            self.receiver = ImageClassifierReceiver(vnMLModel: vnModel)
        } catch {
            // Degrade gracefully: show the camera feed without classification rather than
            // crashing the host app when the model can't be loaded.
            PKLog.model.error("Failed to load image classification model at \(modelURL.path): \(error.localizedDescription)")
            self.receiver = ImageClassifierReceiver(vnMLModel: nil)
        }
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver, options: cameraOptions)
            .onReceive(receiver.$latestPrediction, perform: { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestPrediction = newPrediction
            })
    }
}
