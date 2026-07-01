//
//  LiveRectangleDetectorTests.swift
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
final class LiveRectangleDetectorTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    func testRectangleDetectorViewInit() throws {
        let view = LiveRectangleDetectorView()
        XCTAssertNoThrow(view.body)
    }

#if os(macOS)
    // A synthetic high-contrast rectangle should be detected, so the receiver reports at least one.
    func testRectangleDetectorPositiveMac() throws {
        let receiver = LiveRectangleDetectorReceiver()

        let cgImage = try makeRectangleCGImage()

        receiver.processImage(cgImage)

        let expectation = XCTestExpectation(description: "At least one rectangle is detected")
        receiver.$rectangleCount.dropFirst().sink { newValue in
            if newValue >= 1 {
                expectation.fulfill()
            } else {
                XCTFail("Expected at least one rectangle but received \(newValue)")
            }
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 10)
    }
#endif
}
