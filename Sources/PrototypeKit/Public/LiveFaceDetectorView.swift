import SwiftUI
import Vision

final class LiveFaceDetectorReceiver: PKCameraViewReceiver, ObservableObject {

    @Published var faceCount: Int = 0

    init() {

    }

    func processImage(_ cgImage: CGImage) {
        let request = VNDetectFaceRectanglesRequest { request, _ in
            let count = (request.results as? [VNFaceObservation])?.count ?? 0

            DispatchQueue.main.async {
                self.faceCount = count
            }
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try requestHandler.perform([request])
        } catch {
            PKLog.vision.error("Unable to process image for face detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and detects faces in real-time using the Vision framework.
///
/// The number of faces found in the latest frame is published through the `faceCount` binding. The view
/// drives a ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var faceCount: Int = 0
///
/// LiveFaceDetectorView(faceCount: $faceCount)
/// ```
public struct LiveFaceDetectorView: View {

    @State var receiver: LiveFaceDetectorReceiver

    @Binding var faceCount: Int

    /// Creates a live face detector view.
    ///
    /// - Parameter faceCount: A binding updated with the number of faces detected in the latest frame.
    ///   Defaults to a constant `0` when you only need the on-screen camera feed.
    public init(faceCount: Binding<Int> = .constant(0)) {
        self.receiver = LiveFaceDetectorReceiver()
        self._faceCount = faceCount
    }

    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$faceCount, perform: { newCount in
                self.faceCount = newCount
            })
    }
}
