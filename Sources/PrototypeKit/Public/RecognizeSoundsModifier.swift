//
//  File.swift
//
//
//  Created by James Dale on 12/2/2024.
//

#if os(iOS)
import Foundation
import SwiftUI
import Combine
import SoundAnalysis

public struct SoundAnalysisConfiguration {
    /// Indicates the amount of audio, in seconds, that informs a prediction.
    var inferenceWindowSize = Double(1.5)
    
    /// The amount of overlap between consecutive analysis windows.
    ///
    /// The system performs sound classification on a window-by-window basis. The system divides an
    /// audio stream into windows, and assigns labels and confidence values. This value determines how
    /// much two consecutive windows overlap. For example, 0.9 means that each window shares 90% of
    /// the audio that the previous window uses.
    var overlapFactor = Double(0.9)
    
    var mlModel: MLModel? = nil
    
    public init(inferenceWindowSize: Double = Double(1.5), overlapFactor: Double = Double(0.9), mlModel: MLModel? = nil) {
        self.inferenceWindowSize = inferenceWindowSize
        self.overlapFactor = overlapFactor
        self.mlModel = mlModel
    }
}

@available(iOS 15.0, *)
extension View {
    public func recognizeSounds(recognizedSound: Binding<String?>, configuration: SoundAnalysisConfiguration = .init()) -> some View {
        ModifiedContent(content: self, modifier: RecognizeSoundsModifier(recognizedSound: recognizedSound,
                                                                         configuration: configuration))
    }
}

@available(iOS 15.0, *)
struct RecognizeSoundsModifier: ViewModifier {
    
    @State var cancellables = [AnyCancellable]()
    
    @Binding var recognizedSound: String?
    
    static let classificationSubject = PassthroughSubject<SNClassificationResult, Error>()
    
    init(recognizedSound: Binding<String?>, configuration: SoundAnalysisConfiguration = .init()) {
        self._recognizedSound = recognizedSound
        SystemAudioClassifier.singleton.stopSoundClassification()
        
        SystemAudioClassifier.singleton.startSoundClassification(
            subject: Self.classificationSubject,
            inferenceWindowSize: configuration.inferenceWindowSize,
            overlapFactor: configuration.overlapFactor)
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(Self.classificationSubject.receive(on: DispatchQueue.main).assertNoFailure(), perform: { a in
                self.recognizedSound = a.classifications.first?.identifier
            })
    }
}
#endif
