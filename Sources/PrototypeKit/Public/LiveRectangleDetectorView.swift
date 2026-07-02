import SwiftUI
import Vision

final class LiveRectangleDetectorReceiver: PKCameraViewReceiver, ObservableObject {

    @Published var rectangleCount: Int = 0

    init() {

    }

    func processImage(_ cgImage: CGImage) {
        let request = VNDetectRectanglesRequest { request, error in
            let count = (request.results as? [VNRectangleObservation])?.count ?? 0

            DispatchQueue.main.async {
                self.rectangleCount = count
            }
        }

        // 0 = no limit, so more than the default single rectangle is reported.
        request.maximumObservations = 0

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try requestHandler.perform([request])
        } catch {
            PKLog.vision.error("Unable to process image for rectangle detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and detects rectangular shapes (documents, cards, signs)
/// in real-time using the Vision framework.
///
/// The number of rectangles found in the latest frame is published through the `rectangleCount` binding.
/// The view drives a ``PKCameraView`` internally, so your app target must declare the
/// `NSCameraUsageDescription` (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var rectangleCount: Int = 0
///
/// LiveRectangleDetectorView(rectangleCount: $rectangleCount)
/// ```
public struct LiveRectangleDetectorView: View {

    @State var receiver: LiveRectangleDetectorReceiver

    @Binding var rectangleCount: Int

    /// Creates a live rectangle detector view.
    ///
    /// - Parameter rectangleCount: A binding updated with the number of rectangles detected in the latest
    ///   frame. Defaults to a constant `0` when you only need the on-screen camera feed.
    public init(rectangleCount: Binding<Int> = .constant(0)) {
        self.receiver = LiveRectangleDetectorReceiver()
        self._rectangleCount = rectangleCount
    }

    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$rectangleCount, perform: { newCount in
                self.rectangleCount = newCount
            })
    }
}
