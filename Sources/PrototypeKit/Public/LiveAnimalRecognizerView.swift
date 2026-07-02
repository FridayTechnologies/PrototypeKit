import SwiftUI
import Vision

final class LiveAnimalRecognizerReceiver: PKCameraViewReceiver, ObservableObject {

    @Published var detectedAnimals: [String] = []

    init() {

    }

    func processImage(_ cgImage: CGImage) {
        let request = VNRecognizeAnimalsRequest { request, error in
            guard let results = request.results else { return }
            var latestAnimalResults = [String]()

            for result in results {
                guard let observation = result as? VNRecognizedObjectObservation else { continue }

                if let identifier = observation.labels.first?.identifier {
                    latestAnimalResults.append(identifier)
                }
            }

            DispatchQueue.main.async {
                self.detectedAnimals = latestAnimalResults
            }
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try requestHandler.perform([request])
        } catch {
            PKLog.vision.error("Unable to process image for animal recognition: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and recognizes animals (cats and dogs) in
/// real-time using the Vision framework.
///
/// Each recognized animal label is published through the `detectedAnimals` binding. The view drives a
/// ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var detectedAnimals: [String] = []
///
/// LiveAnimalRecognizerView(detectedAnimals: $detectedAnimals)
/// ```
public struct LiveAnimalRecognizerView: View {

    @State var receiver: LiveAnimalRecognizerReceiver

    @Binding var detectedAnimals: [String]

    /// Creates a live animal recognizer view.
    ///
    /// - Parameter detectedAnimals: A binding updated with the array of animal labels (e.g. `"Cat"`,
    ///   `"Dog"`) recognized in the latest frame. Defaults to a constant empty array when you only need
    ///   the on-screen camera feed.
    public init(detectedAnimals: Binding<[String]> = .constant([])) {
        self.receiver = LiveAnimalRecognizerReceiver()
        self._detectedAnimals = detectedAnimals
    }

    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$detectedAnimals, perform: { newAnimals in
                self.detectedAnimals = newAnimals
            })
    }
}
