//
//  ObjectDetectorView.swift
//
//
//  Created by James Dale.
//

import SwiftUI
import CoreML
import Vision

/// A single object located by an ``ObjectDetectorView`` in a camera frame.
///
/// This is the richer counterpart to the label-only (`[String]`) API: alongside the most likely
/// label it carries the detection confidence and the object's location in the frame, so you can draw
/// bounding boxes or reason about where things are.
public struct DetectedObject: Equatable {

    /// The most likely label for the object (the top Vision classification).
    public let label: String

    /// The confidence of ``label``, from `0` to `1`.
    public let confidence: Float

    /// The object's location in the image in normalized coordinates (`0`–`1`), with the origin at the
    /// bottom-left, exactly as Vision reports it (`VNRecognizedObjectObservation.boundingBox`).
    ///
    /// SwiftUI's coordinate space has its origin at the top-left, so flip the `y` axis
    /// (`1 - boundingBox.maxY`) when positioning an overlay.
    public let boundingBox: CGRect

    /// Creates a detected object.
    ///
    /// - Parameters:
    ///   - label: The most likely label for the object.
    ///   - confidence: The confidence of `label`, from `0` to `1`.
    ///   - boundingBox: The object's normalized bounding box (origin bottom-left).
    public init(label: String, confidence: Float, boundingBox: CGRect) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

final class ObjectDetectorReceiver: PKCameraViewReceiver, ObservableObject {

    private let vnCoreMLModel: VNCoreMLModel?

    @Published var detectedObjects: [DetectedObject] = []

    private lazy var request: VNCoreMLRequest? = {
        guard let model = self.vnCoreMLModel else { return nil }
        return VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                PKLog.vision.error("Object detection request failed: \(error.localizedDescription)")
                return
            }
            let results = request.results as? [VNRecognizedObjectObservation] ?? []
            let objects = results.compactMap { observation -> DetectedObject? in
                guard let top = observation.labels.first else { return nil }
                return DetectedObject(label: top.identifier,
                                      confidence: top.confidence,
                                      boundingBox: observation.boundingBox)
            }

            DispatchQueue.main.async {
                self?.detectedObjects = objects
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
/// objects found in the latest frame. The view drives a ``PKCameraView`` internally, so your app target
/// must declare the `NSCameraUsageDescription` (Privacy - Camera Usage Description) key in its Info
/// properties.
///
/// Two flavours of binding are available. Pass a `Binding<[String]>` when you only care about *what*
/// was detected:
///
/// ```swift
/// @State var detectedObjects: [String] = []
///
/// ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
///                    detectedObjects: $detectedObjects)
/// ```
///
/// Or pass a `Binding<[DetectedObject]>` when you also want *where* — each ``DetectedObject`` carries a
/// label, a confidence, and a normalized bounding box, so you can draw overlays:
///
/// ```swift
/// @State var detectedObjects: [DetectedObject] = []
///
/// ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
///                    detectedObjects: $detectedObjects)
/// ```
public struct ObjectDetectorView: View {

    @State var receiver: ObjectDetectorReceiver

    /// Forwards the receiver's detections to the caller's binding. Set once at init to map the rich
    /// ``DetectedObject`` values into whichever binding flavour the caller chose.
    private let publish: ([DetectedObject]) -> Void

    private let cameraOptions: CameraOptions?

    private let onError: ((PrototypeKitError) -> Void)?

    private let loadError: PrototypeKitError?

    /// Loads the model and wires up the receiver. Shared by the public initializers, which differ only
    /// in how they forward detections to the caller.
    private init(modelURL: URL,
                 camera: CameraOptions?,
                 onError: ((PrototypeKitError) -> Void)?,
                 publish: @escaping ([DetectedObject]) -> Void) {
        self.publish = publish
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

    /// Creates an object detector view that reports the *labels* of detected objects.
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
        self.init(modelURL: modelURL, camera: camera, onError: onError) { objects in
            detectedObjects.wrappedValue = objects.map(\.label)
        }
    }

    /// Creates an object detector view that reports each detected object's label, confidence, and
    /// bounding box.
    ///
    /// Use this initializer when you need to know *where* objects are (for example, to draw bounding
    /// boxes) rather than only *what* was detected.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML object-detection model to load,
    ///     typically `YourModel.urlOfModelInThisBundle`.
    ///   - detectedObjects: A binding updated with the ``DetectedObject`` values found in the latest
    ///     frame, each carrying a label, a confidence, and a normalized bounding box.
    ///   - camera: Optional ``CameraOptions`` selecting the camera position and device type. Pass `nil`
    ///     to use the default back wide-angle camera. (Ignored on macOS.)
    ///   - onError: An optional closure called (on the main thread) if the model fails to load. The view
    ///     still shows the camera feed without detection; use this to surface the failure in your UI.
    public init(modelURL: URL,
                detectedObjects: Binding<[DetectedObject]>,
                camera: CameraOptions? = nil,
                onError: ((PrototypeKitError) -> Void)? = nil) {
        self.init(modelURL: modelURL, camera: camera, onError: onError) { objects in
            detectedObjects.wrappedValue = objects
        }
    }

    public var body: some View {
        PKCameraView(receiver: receiver, options: cameraOptions)
            .onReceive(receiver.$detectedObjects, perform: { newObjects in
                self.publish(newObjects)
            })
            .onAppear {
                if let loadError = loadError { onError?(loadError) }
            }
    }
}
