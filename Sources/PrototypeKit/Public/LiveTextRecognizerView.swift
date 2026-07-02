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
            PKLog.vision.error("Unable to process image for text recognition: \(error.localizedDescription)")
        }
    }
}

/// A SwiftUI view that shows a live camera feed and recognizes text in real-time using the Vision framework.
///
/// Each detected line of text is published through the `detectedText` binding. The view drives a
/// ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var detectedText: [String] = []
///
/// LiveTextRecognizerView(detectedText: $detectedText)
/// ```
public struct LiveTextRecognizerView: View {

    @State var receiver: LiveTextRecognizerReceiver

    @Binding var detectedText: [String]

    /// Creates a live text recognizer view.
    ///
    /// - Parameter detectedText: A binding updated with the array of text lines found in the latest frame.
    ///   Defaults to a constant empty array when you only need the on-screen camera feed.
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
