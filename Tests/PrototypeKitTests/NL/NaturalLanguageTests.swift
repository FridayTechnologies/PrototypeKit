//
//  NaturalLanguageTests.swift
//
//
//  Created by PrototypeKit.
//

import XCTest
import SwiftUI

@testable
import PrototypeKit

final class NaturalLanguageTests: XCTestCase {

    // MARK: - Sentiment

    // An empty string has nothing to score, so the analyzer should report a neutral 0 without crashing.
    func testSentimentEmptyStringIsNeutral() {
        XCTAssertEqual(NaturalLanguageAnalyzer.sentimentScore(for: ""), 0)
    }

    // Sentiment scores are always bounded to the [-1, 1] range regardless of the input.
    func testSentimentIsWithinBounds() {
        let samples = ["I absolutely love this, it is wonderful!",
                       "This is terrible and I hate it.",
                       "The book is on the table."]

        for sample in samples {
            let score = NaturalLanguageAnalyzer.sentimentScore(for: sample)
            XCTAssertGreaterThanOrEqual(score, -1)
            XCTAssertLessThanOrEqual(score, 1)
        }
    }

    // MARK: - Language identification

    // NLLanguageRecognizer is deterministic for clear input, so a plain English sentence resolves to "en".
    func testDominantLanguageEnglish() {
        XCTAssertEqual(NaturalLanguageAnalyzer.dominantLanguage(for: "The quick brown fox jumps over the lazy dog."),
                       "en")
    }

    func testDominantLanguageFrench() {
        XCTAssertEqual(NaturalLanguageAnalyzer.dominantLanguage(for: "Bonjour, je m'appelle Jean et j'habite à Paris."),
                       "fr")
    }

    func testDominantLanguageEmptyStringIsNil() {
        XCTAssertNil(NaturalLanguageAnalyzer.dominantLanguage(for: ""))
    }

    // MARK: - Entities

    func testEntitiesEmptyStringIsEmpty() {
        XCTAssertTrue(NaturalLanguageAnalyzer.entities(in: "").isEmpty)
    }

    // Text with no proper nouns should surface no named entities.
    func testEntitiesPlainTextHasNone() {
        XCTAssertTrue(NaturalLanguageAnalyzer.entities(in: "the cat sat on the mat").isEmpty)
    }

    // A sentence naming a place should surface at least one entity, and every entry is non-empty.
    func testEntitiesRecognizesNames() {
        let entities = NaturalLanguageAnalyzer.entities(in: "Tim Cook announced the news in London.")
        XCTAssertFalse(entities.isEmpty)
        XCTAssertFalse(entities.contains(where: { $0.isEmpty }))
    }

    // MARK: - Modifier wiring

    // Applying each modifier should build a valid view without throwing.
    func testModifiersBuild() {
        let view = Text("hello")
            .analyzeSentiment(text: "hello", score: .constant(0))
            .identifyLanguage(text: "hello", language: .constant(nil))
            .tagEntities(text: "hello", entities: .constant([]))
        XCTAssertNotNil(view)
    }
}
