//
//  ObjectDetectorTests.swift
//
//
//  Created by PrototypeKit.
//

import XCTest
import Vision
import CoreML
import Combine

@testable
import PrototypeKit

@available(iOS 16.0, *)
final class ObjectDetectorTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    /// A URL that does not point at a real Core ML model.
    private var bogusModelURL: URL {
        URL(fileURLWithPath: "/nonexistent/PrototypeKit/DoesNotExist.mlmodelc")
    }

    // A bad model URL must degrade gracefully (camera feed, no detections) rather than crash.
    func testObjectDetectorViewInitWithBadURLDoesNotCrash() throws {
        let view = ObjectDetectorView(modelURL: bogusModelURL)
        XCTAssertNoThrow(view.body)
    }

    func testObjectDetectorViewAcceptsOnError() throws {
        let view = ObjectDetectorView(modelURL: bogusModelURL, onError: { _ in })
        XCTAssertNoThrow(view.body)
    }

    // With no model loaded, the receiver must ignore frames and publish no detections.
    func testObjectDetectorReceiverWithNilModelIgnoresFrames() throws {
        let receiver = ObjectDetectorReceiver(vnMLModel: nil)
        let frame = try makeSolidColorCGImage(width: 64, height: 64)

        receiver.processImage(frame)

        XCTAssertTrue(receiver.detectedObjects.isEmpty)
    }
}
