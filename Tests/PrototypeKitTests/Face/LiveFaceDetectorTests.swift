//
//  LiveFaceDetectorTests.swift
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
final class LiveFaceDetectorTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    func testFaceDetectorViewInit() throws {
        let view = LiveFaceDetectorView()
        XCTAssertNoThrow(view.body)
    }

#if os(macOS)
    // A blank frame contains no faces, so the receiver should report a count of 0 without
    // crashing — this validates the request/publisher wiring.
    func testFaceDetectorBlankImageMac() throws {
        let receiver = LiveFaceDetectorReceiver()

        let cgImage = try makeSolidColorCGImage(width: 200, height: 200)

        receiver.processImage(cgImage)

        let expectation = XCTestExpectation(description: "No faces detected in a blank frame")
        receiver.$faceCount.dropFirst().sink { newValue in
            XCTAssertEqual(newValue, 0,
                           "Expected no faces in a blank frame but received \(newValue)")
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 10)
    }
#endif
}
