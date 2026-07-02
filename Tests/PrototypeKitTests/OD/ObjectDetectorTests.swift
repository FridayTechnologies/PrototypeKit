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

    // The DetectedObject-based initializer must also degrade gracefully on a bad model URL.
    func testObjectDetectorViewWithDetectedObjectsBindingDoesNotCrash() throws {
        let view = ObjectDetectorView(modelURL: bogusModelURL,
                                      detectedObjects: .constant([DetectedObject]()))
        XCTAssertNoThrow(view.body)
    }

    func testObjectDetectorViewWithDetectedObjectsBindingAcceptsOnError() throws {
        let view = ObjectDetectorView(modelURL: bogusModelURL,
                                      detectedObjects: .constant([DetectedObject]()),
                                      onError: { _ in })
        XCTAssertNoThrow(view.body)
    }

    // With no model loaded, the receiver must ignore frames and publish no detections.
    func testObjectDetectorReceiverWithNilModelIgnoresFrames() throws {
        let receiver = ObjectDetectorReceiver(vnMLModel: nil)
        let frame = try makeSolidColorCGImage(width: 64, height: 64)

        receiver.processImage(frame)

        XCTAssertTrue(receiver.detectedObjects.isEmpty)
    }

    // DetectedObject is a simple value type carrying label, confidence, and bounding box.
    func testDetectedObjectStoresItsValues() {
        let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let object = DetectedObject(label: "dog", confidence: 0.9, boundingBox: box)

        XCTAssertEqual(object.label, "dog")
        XCTAssertEqual(object.confidence, 0.9, accuracy: 0.0001)
        XCTAssertEqual(object.boundingBox, box)
        XCTAssertEqual(object, DetectedObject(label: "dog", confidence: 0.9, boundingBox: box))
        XCTAssertNotEqual(object, DetectedObject(label: "cat", confidence: 0.9, boundingBox: box))
    }
}
