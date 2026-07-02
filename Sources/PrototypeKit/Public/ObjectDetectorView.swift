//
//  ObjectDetectorView.swift
//
//
//  Created by James Dale.
//

import SwiftUI
import CoreML
import Vision

final class ObjectDetectorReceiver: PKCameraViewReceiver, ObservableObject {

    private let vnCoreMLModel: VNCoreMLModel?

    @Published var detectedObjects: [String] = []

    private lazy var request: VNCoreMLRequest? = {
        guard let model = self.vnCoreMLModel else { return nil }
        return VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                PKLog.vision.error("Object detection request failed: \(error.localizedDescription)")
                return
            }
            let results = request.results as? [VNRecognizedObjectObservation] ?? []
            let labels = results.compactMap { $0.labels.first?.identifier }

            DispatchQueue.main.async {
                self?.detectedObjects = labels
            }
        }
    }()

    /// Creates a receiver for the given Vision model.
    ///
    /// - Parameter vnMLModel: The Vision Core ML object-detection model to run on frames, or `nil` when
    ///   the model failed to load. When `nil`, frames are ignored and no detections are published.
    init(vnMLModel: VNCoreMLModel?) {
        self.vnCoreMLModel = vnMLModel
    }

    func processImage(_ cgImage: CGImage) {
        guard let request = request else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])

        // Object detectors localize objects across the whole frame, so scale (rather than crop) the
        // image into the model's input size to avoid discarding objects near the edges.
        request.imageCropAndScaleOption = .scaleFill
        do {
            try handler.perform([request])
        } catch {
            PKLog.vision.error("Failed to perform object detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and detects objects in each frame using a Core ML
/// object detector.
///
/// Provide the URL of a Create ML / Core ML **Object Detector** model and a binding to receive the
/// labels of the objects found in the latest frame. The view drives a ``PKCameraView`` internally, so
/// your app target must declare the `NSCameraUsageDescription` (Privacy - Camera Usage Description) key
/// in its Info properties.
///
/// ```swift
/// @State var detectedObjects: [String] = []
///
/// ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
///                    detectedObjects: $detectedObjects)
/// ```
///
/// - Note: Only the top label of each detected object is surfaced; bounding boxes and confidence
///   scores are not exposed.
public struct ObjectDetectorView: View {

    @State var receiver: ObjectDetectorReceiver

    @Binding var detectedObjects: [String]

    private let cameraOptions: CameraOptions?

    private let onError: ((PrototypeKitError) -> Void)?

    private let loadError: PrototypeKitError?

    /// Creates an object detector view backed by a Core ML model.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML object-detection model to load,
    ///     typically `YourModel.urlOfModelInThisBundle`.
    ///   - detectedObjects: A binding updated with the labels of the objects detected in the latest
    ///     frame. Defaults to a constant empty array when you only need the on-screen camera feed.
    ///   - camera: Optional ``CameraOptions`` selecting the camera position and device type. Pass `nil`
    ///     to use the default back wide-angle camera. (Ignored on macOS.)
    ///   - onError: An optional closure called (on the main thread) if the model fails to load. The view
    ///     still shows the camera feed without detection; use this to surface the failure in your UI.
    public init(modelURL: URL,
                detectedObjects: Binding<[String]> = .constant([]),
                camera: CameraOptions? = nil,
                onError: ((PrototypeKitError) -> Void)? = nil) {
        self._detectedObjects = detectedObjects
        self.cameraOptions = camera
        self.onError = onError
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let vnModel = try VNCoreMLModel(for: mlModel)
            self.receiver = ObjectDetectorReceiver(vnMLModel: vnModel)
            self.loadError = nil
        } catch {
            // Degrade gracefully: show the camera feed without detection rather than
            // crashing the host app when the model can't be loaded.
            PKLog.model.error("Failed to load object detection model at \(modelURL.path): \(error.localizedDescription)")
            self.receiver = ObjectDetectorReceiver(vnMLModel: nil)
            self.loadError = .modelLoadFailed(url: modelURL, underlying: error)
        }
    }

    public var body: some View {
        PKCameraView(receiver: receiver, options: cameraOptions)
            .onReceive(receiver.$detectedObjects, perform: { newObjects in
                self.detectedObjects = newObjects
            })
            .onAppear {
                if let loadError = loadError { onError?(loadError) }
            }
    }
}
