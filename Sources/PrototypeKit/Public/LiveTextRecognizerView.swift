//
//  LiveTextRecognizerView.swift
//
//
//  Created by James Dale on 2/2/2024.
//

import SwiftUI
import CoreML
import Vision

final class LiveTextRecognizerReceiver: PKCameraViewReceiver, ObservableObject {
    
    @Published var detectedText: [String] = []
    
    init() {
        
    }
    
    func processImage(_ cgImage: CGImage) {
        let request = VNRecognizeTextRequest { request, error in
            guard let results = request.results else { return }
            var latestTextDetectionResults = [String]()
            
            for result in results {
                guard let observation = result as? VNRecognizedTextObservation else { continue }
                
                if let text = observation.topCandidates(1).first?.string {
                    latestTextDetectionResults.append(text)
                }
            }
            
            DispatchQueue.main.async {
                self.detectedText = latestTextDetectionResults
            }
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to receive image")
        }
    }
}

public struct LiveTextRecognizerView: View {
    
    @State var receiver: LiveTextRecognizerReceiver
    
    @Binding var detectedText: [String]
    
    public init(detectedText: Binding<[String]> = .constant([])) {
        self.receiver = LiveTextRecognizerReceiver()
        self._detectedText = detectedText
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$detectedText, perform: { newPredictions in
                self.detectedText = newPredictions
            })
    }
}
