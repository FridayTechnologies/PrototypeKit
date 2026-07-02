import SwiftUI
import Vision

final class LiveBarcodeRecognizerReceiver: PKCameraViewReceiver, ObservableObject {
    
    @Published var detectedBarcodes: [String] = []
    
    init() {
        
    }
    
    func processImage(_ cgImage: CGImage) {
        let request = VNDetectBarcodesRequest { request, _ in
            guard let results = request.results else { return }
            var latestBarcodeResults = [String]()
            
            for result in results {
                guard let observation = result as? VNBarcodeObservation else { continue }
                
                if let payload = observation.payloadStringValue {
                    latestBarcodeResults.append(payload)
                }
            }
            
            DispatchQueue.main.async {
                self.detectedBarcodes = latestBarcodeResults
            }
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try requestHandler.perform([request])
        } catch {
            PKLog.vision.error("Unable to process image for barcode detection: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and detects barcodes in real-time using the Vision framework.
///
/// Each decoded barcode payload is published through the `detectedBarcodes` binding. The view drives a
/// ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var detectedBarcodes: [String] = []
///
/// LiveBarcodeRecognizerView(detectedBarcodes: $detectedBarcodes)
/// ```
public struct LiveBarcodeRecognizerView: View {

    @State var receiver: LiveBarcodeRecognizerReceiver

    @Binding var detectedBarcodes: [String]

    /// Creates a live barcode recognizer view.
    ///
    /// - Parameter detectedBarcodes: A binding updated with the array of barcode payload strings decoded
    ///   in the latest frame. Defaults to a constant empty array when you only need the on-screen camera feed.
    public init(detectedBarcodes: Binding<[String]> = .constant([])) {
        self.receiver = LiveBarcodeRecognizerReceiver()
        self._detectedBarcodes = detectedBarcodes
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$detectedBarcodes, perform: { newBarcodes in
                self.detectedBarcodes = newBarcodes
            })
    }
}
