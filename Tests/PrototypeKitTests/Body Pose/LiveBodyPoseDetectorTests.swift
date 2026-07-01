//
//  LiveBodyPoseDetectorTests.swift
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
final class LiveBodyPoseDetectorTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    func testBodyPoseDetectorViewInit() throws {
        let view = LiveBodyPoseDetectorView()
        XCTAssertNoThrow(view.body)
    }

#if os(macOS)
    // A blank frame contains no bodies, so the receiver should report a count of 0 without
    // crashing — this validates the request/publisher wiring.
    func testBodyPoseDetectorBlankImageMac() throws {
        let receiver = LiveBodyPoseDetectorReceiver()

        let cgImage = try makeSolidColorCGImage(width: 200, height: 200)

        receiver.processImage(cgImage)

        let expectation = XCTestExpectation(description: "No bodies detected in a blank frame")
        receiver.$bodyCount.dropFirst().sink { newValue in
            XCTAssertEqual(newValue, 0,
                           "Expected no bodies in a blank frame but received \(newValue)")
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 10)
    }
#endif
}
