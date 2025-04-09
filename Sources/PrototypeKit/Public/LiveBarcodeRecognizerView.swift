import SwiftUI
import Vision

final class LiveBarcodeRecognizerReceiver: PKCameraViewReceiver, ObservableObject {
    
    @Published var detectedBarcodes: [String] = []
    
    init() {
        
    }
    
    func processImage(_ cgImage: CGImage) {
        let request = VNDetectBarcodesRequest { request, error in
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
            print("Unable to process image for barcode detection")
        }
    }
}

public struct LiveBarcodeRecognizerView: View {
    
    @State var receiver: LiveBarcodeRecognizerReceiver
    
    @Binding var detectedBarcodes: [String]
    
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