//
//  RecognizeSoundsModifier.swift
//
//
//  Created by James Dale on 12/2/2024.
//

#if os(iOS)
import Foundation
import SwiftUI
import Combine
import SoundAnalysis
import CoreML

/// Configuration options for live sound recognition via the ``recognizeSounds(recognizedSound:configuration:)`` modifier.
///
/// Use the defaults for the built-in system sound classifier, or supply a custom Core ML model and tune the
/// analysis window for your use case.
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
    
    /// Optional custom Core ML model for sound classification. If nil, uses the system sound classifier.
    var mlModel: MLModel? = nil
    
    /// Creates a sound analysis configuration.
    ///
    /// - Parameters:
    ///   - inferenceWindowSize: The amount of audio, in seconds, that informs each prediction. Larger
    ///     windows can improve accuracy for longer sounds at the cost of responsiveness. Defaults to `1.5`.
    ///   - overlapFactor: How much consecutive analysis windows overlap, from `0` to `1`. Higher values
    ///     produce more frequent predictions. Defaults to `0.9`.
    ///   - mlModel: An optional custom Core ML sound-classification model. When `nil`, the built-in system
    ///     sound classifier is used.
    public init(inferenceWindowSize: Double = Double(1.5), overlapFactor: Double = Double(0.9), mlModel: MLModel? = nil) {
        self.inferenceWindowSize = inferenceWindowSize
        self.overlapFactor = overlapFactor
        self.mlModel = mlModel
    }
}

@available(iOS 15.0, *)
extension View {
    /// Listens to the microphone and classifies sounds in real-time, updating a binding with the top label.
    ///
    /// Attach this modifier to any view to begin sound recognition. Your app target must declare the
    /// `NSMicrophoneUsageDescription` (Privacy - Microphone Usage Description) key in its Info properties,
    /// otherwise classification fails silently.
    ///
    /// ```swift
    /// @State var recognizedSound: String?
    ///
    /// Text(recognizedSound ?? "Listening…")
    ///     .recognizeSounds(recognizedSound: $recognizedSound)
    /// ```
    ///
    /// - Parameters:
    ///   - recognizedSound: A binding updated with the most recently recognized sound label, or `nil`
    ///     when nothing has been classified yet.
    ///   - configuration: A ``SoundAnalysisConfiguration`` controlling the analysis window and optional
    ///     custom Core ML model. Defaults to the built-in system sound classifier.
    /// - Returns: A view that performs live sound recognition while visible.
    /// - Important: Available on iOS 15.0+ only; sound recognition is not supported on macOS.
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
        
        if let customModel = configuration.mlModel {
            // Use custom Core ML model for sound classification
            do {
                let request = try SNClassifySoundRequest(mlModel: customModel)
                request.windowDuration = CMTimeMakeWithSeconds(configuration.inferenceWindowSize, preferredTimescale: 48_000)
                request.overlapFactor = configuration.overlapFactor

                SystemAudioClassifier.singleton.startSoundClassification(
                    subject: Self.classificationSubject,
                    request: request)
            } catch {
                // Degrade gracefully: no classification starts rather than crashing the host app
                // when the custom model can't back a sound request.
                PKLog.audio.error("Failed to create sound request from custom model: \(error.localizedDescription)")
            }
        } else {
            // Use system sound classifier
            SystemAudioClassifier.singleton.startSoundClassification(
                subject: Self.classificationSubject,
                inferenceWindowSize: configuration.inferenceWindowSize,
                overlapFactor: configuration.overlapFactor)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(classificationPublisher, perform: { result in
                self.recognizedSound = result.classifications.first?.identifier
            })
    }

    /// A main-thread publisher that never fails.
    ///
    /// `SystemAudioClassifier` reports interruptions and errors as a Combine `.failure` completion.
    /// Surfacing that directly to `onReceive` with `assertNoFailure()` would trap and crash the host
    /// app, so we log the error and swallow it, leaving the last recognized sound in place.
    private var classificationPublisher: AnyPublisher<SNClassificationResult, Never> {
        Self.classificationSubject
            .receive(on: DispatchQueue.main)
            .catch { error -> Empty<SNClassificationResult, Never> in
                PKLog.audio.error("Sound classification failed: \(error.localizedDescription)")
                return Empty<SNClassificationResult, Never>()
            }
            .eraseToAnyPublisher()
    }
}
#endif
