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

    // Named-entity recognition depends on models that are not provisioned in the iOS Simulator
    // (CI logs show "queryMetaDataSync" errors), so we don't assert that specific entities are found —
    // matching how the Vision tests only assert benign outcomes off-device. Instead we verify the
    // output contract: any returned entity is a non-empty substring of the input.
    func testEntitiesOutputIsWellFormed() {
        let text = "Tim Cook announced the news in London."
        let entities = NaturalLanguageAnalyzer.entities(in: text)

        for entity in entities {
            XCTAssertFalse(entity.isEmpty)
            XCTAssertTrue(text.contains(entity),
                          "Entity \"\(entity)\" should be a substring of the input")
        }
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
