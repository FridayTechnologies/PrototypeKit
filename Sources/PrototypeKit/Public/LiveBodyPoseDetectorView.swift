import SwiftUI
import Vision

final class LiveBodyPoseDetectorReceiver: PKCameraViewReceiver, ObservableObject {

    @Published var bodyCount: Int = 0

    init() {

    }

    func processImage(_ cgImage: CGImage) {
        let request = VNDetectHumanBodyPoseRequest { request, error in
            let count = (request.results as? [VNHumanBodyPoseObservation])?.count ?? 0

            DispatchQueue.main.async {
                self.bodyCount = count
            }
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try requestHandler.perform([request])
        } catch {
            PKLog.vision.error("Unable to process image for body pose detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and detects human body poses in real-time using the
/// Vision framework.
///
/// The number of bodies found in the latest frame is published through the `bodyCount` binding. The view
/// drives a ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var bodyCount: Int = 0
///
/// LiveBodyPoseDetectorView(bodyCount: $bodyCount)
/// ```
public struct LiveBodyPoseDetectorView: View {

    @State var receiver: LiveBodyPoseDetectorReceiver

    @Binding var bodyCount: Int

    /// Creates a live body pose detector view.
    ///
    /// - Parameter bodyCount: A binding updated with the number of human bodies detected in the latest
    ///   frame. Defaults to a constant `0` when you only need the on-screen camera feed.
    public init(bodyCount: Binding<Int> = .constant(0)) {
        self.receiver = LiveBodyPoseDetectorReceiver()
        self._bodyCount = bodyCount
    }

    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$bodyCount, perform: { newCount in
                self.bodyCount = newCount
            })
    }
}
