//
//  GracefulFailureTests.swift
//
//
//  Verifies that PrototypeKit degrades gracefully instead of crashing when given bad input
//  (missing/invalid models). A library must never take down the host app.
//

import XCTest
import CoreML
import Vision

@testable
import PrototypeKit

final class GracefulFailureTests: XCTestCase {

    /// A URL that does not point at a real Core ML model.
    private var bogusModelURL: URL {
        URL(fileURLWithPath: "/nonexistent/PrototypeKit/DoesNotExist.mlmodelc")
    }

    // MARK: - View initializers must not crash on a bad model URL

    func testImageClassifierViewInitWithBadURLDoesNotCrash() throws {
        // Previously this path called fatalError(); it must now degrade gracefully.
        let view = ImageClassifierView(modelURL: bogusModelURL)
        XCTAssertNoThrow(view.body)
    }

    func testHandPoseClassifierViewInitWithBadURLDoesNotCrash() throws {
        let view = HandPoseClassifierView(modelURL: bogusModelURL)
        XCTAssertNoThrow(view.body)
    }

    // MARK: - Receivers with no model must ignore frames rather than crash

    func testImageClassifierReceiverWithNilModelIgnoresFrames() throws {
        let receiver = ImageClassifierReceiver(vnMLModel: nil)
        let frame = try makeSolidColorCGImage(width: 64, height: 64)

        receiver.processImage(frame)

        XCTAssertNil(receiver.latestPrediction)
    }

    func testHandPoseClassifierReceiverWithNilModelIgnoresFrames() throws {
        let receiver = HandPoseClassifierReceiver(mlModel: nil)
        let frame = try makeSolidColorCGImage(width: 64, height: 64)

        receiver.processImage(frame)

        XCTAssertNil(receiver.latestPrediction)
    }

    // MARK: - Activity classification (iOS only) must stay inert without a model

    #if os(iOS)
    func testActivityClassifierReceiverWithNilModelStaysInert() throws {
        let receiver = ActivityClassifierReceiver(mlModel: nil,
                                                  configuration: .init())
        // start()/stop() must be safe no-ops when there is no model to run.
        receiver.start()
        receiver.stop()

        XCTAssertNil(receiver.latestPrediction)
    }
    #endif
}
