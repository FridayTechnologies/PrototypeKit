//
//  NaturalLanguageModifiers.swift
//
//
//  Created by PrototypeKit.
//

import Foundation
import SwiftUI
import NaturalLanguage

/// Runs Apple's on-device `NaturalLanguage` models over a piece of text.
///
/// Unlike the camera and sound features, natural-language analysis is a pure function of its input:
/// text goes in, a value comes out. There is no capture pipeline to start or stop, no permissions to
/// request, and no Core ML model to bundle — everything ships with the operating system. This makes it
/// the gentlest possible introduction to on-device machine-learning inference.
///
/// You will usually reach for the ``SwiftUI/View/analyzeSentiment(text:score:)``,
/// ``SwiftUI/View/identifyLanguage(text:language:)``, and ``SwiftUI/View/tagEntities(text:entities:)``
/// view modifiers rather than calling these methods directly, but they are available if you want the
/// result without a SwiftUI binding.
enum NaturalLanguageAnalyzer {

    /// Scores the overall sentiment of `text` from `-1` (very negative) to `1` (very positive).
    ///
    /// Uses `NLTagger`'s built-in `.sentimentScore` scheme. An empty string, or text the model cannot
    /// score, returns `0` (neutral).
    static func sentimentScore(for text: String) -> Double {
        guard !text.isEmpty else { return 0 }

        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (sentiment, _) = tagger.tag(at: text.startIndex,
                                        unit: .paragraph,
                                        scheme: .sentimentScore)

        return Double(sentiment?.rawValue ?? "0") ?? 0
    }

    /// Identifies the dominant language of `text` as a BCP-47 language code (for example `"en"`, `"fr"`).
    ///
    /// Returns `nil` when the text is empty or the language cannot be determined.
    static func dominantLanguage(for text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        return recognizer.dominantLanguage?.rawValue
    }

    /// Extracts named entities — people, places, and organizations — mentioned in `text`.
    ///
    /// Uses `NLTagger`'s built-in `.nameType` scheme. Multi-word names (such as "Tim Cook") are joined
    /// into a single entry. Returns an empty array when no entities are found.
    static func entities(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let recognizedKinds: Set<NLTag> = [.personalName, .placeName, .organizationName]
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        var entities: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, range in
            if let tag = tag, recognizedKinds.contains(tag) {
                entities.append(String(text[range]))
            }
            return true
        }

        return entities
    }
}

public extension View {

    /// Scores the sentiment of `text` on-device and writes the result to a binding.
    ///
    /// Attach this modifier to any view and it will analyse `text` using Apple's `NaturalLanguage`
    /// framework, updating `score` with a value from `-1` (very negative) through `0` (neutral) to
    /// `1` (very positive). The analysis re-runs whenever `text` changes. No camera, microphone,
    /// permissions, or Core ML model are required, and it works on both iOS and macOS.
    ///
    /// ```swift
    /// @State var text = "I love this!"
    /// @State var score: Double = 0
    ///
    /// TextField("Type something", text: $text)
    ///     .analyzeSentiment(text: text, score: $score)
    /// Text("Sentiment: \(score, specifier: "%.2f")")
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to analyse.
    ///   - score: A binding updated with the sentiment score, from `-1` to `1`.
    /// - Returns: A view that keeps `score` in sync with the sentiment of `text`.
    func analyzeSentiment(text: String, score: Binding<Double>) -> some View {
        modifier(AnalyzeSentimentModifier(text: text, score: score))
    }

    /// Identifies the dominant language of `text` on-device and writes the result to a binding.
    ///
    /// Attach this modifier to any view and it will detect the language of `text` using Apple's
    /// `NaturalLanguage` framework, updating `language` with a BCP-47 language code such as `"en"` or
    /// `"fr"` (or `nil` when the language cannot be determined). The detection re-runs whenever `text`
    /// changes. No permissions or Core ML model are required, and it works on both iOS and macOS.
    ///
    /// ```swift
    /// @State var text = "Bonjour tout le monde"
    /// @State var language: String?
    ///
    /// Text(language ?? "Detecting…")
    ///     .identifyLanguage(text: text, language: $language)
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to analyse.
    ///   - language: A binding updated with the detected BCP-47 language code, or `nil`.
    /// - Returns: A view that keeps `language` in sync with the dominant language of `text`.
    func identifyLanguage(text: String, language: Binding<String?>) -> some View {
        modifier(IdentifyLanguageModifier(text: text, language: language))
    }

    /// Extracts named entities from `text` on-device and writes them to a binding.
    ///
    /// Attach this modifier to any view and it will find the people, places, and organizations
    /// mentioned in `text` using Apple's `NaturalLanguage` framework, updating `entities` with the
    /// recognized names. The analysis re-runs whenever `text` changes. No permissions or Core ML
    /// model are required, and it works on both iOS and macOS.
    ///
    /// ```swift
    /// @State var text = "Tim Cook announced the news in London."
    /// @State var entities: [String] = []
    ///
    /// TextField("Type something", text: $text)
    ///     .tagEntities(text: text, entities: $entities)
    /// ForEach(entities, id: \.self) { Text($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to analyse.
    ///   - entities: A binding updated with the recognized entity names.
    /// - Returns: A view that keeps `entities` in sync with the named entities in `text`.
    func tagEntities(text: String, entities: Binding<[String]>) -> some View {
        modifier(TagEntitiesModifier(text: text, entities: entities))
    }
}

struct AnalyzeSentimentModifier: ViewModifier {

    let text: String

    @Binding var score: Double

    func body(content: Content) -> some View {
        content
            .onAppear { score = NaturalLanguageAnalyzer.sentimentScore(for: text) }
            .onChange(of: text) { newText in
                score = NaturalLanguageAnalyzer.sentimentScore(for: newText)
            }
    }
}

struct IdentifyLanguageModifier: ViewModifier {

    let text: String

    @Binding var language: String?

    func body(content: Content) -> some View {
        content
            .onAppear { language = NaturalLanguageAnalyzer.dominantLanguage(for: text) }
            .onChange(of: text) { newText in
                language = NaturalLanguageAnalyzer.dominantLanguage(for: newText)
            }
    }
}

struct TagEntitiesModifier: ViewModifier {

    let text: String

    @Binding var entities: [String]

    func body(content: Content) -> some View {
        content
            .onAppear { entities = NaturalLanguageAnalyzer.entities(in: text) }
            .onChange(of: text) { newText in
                entities = NaturalLanguageAnalyzer.entities(in: newText)
            }
    }
}
