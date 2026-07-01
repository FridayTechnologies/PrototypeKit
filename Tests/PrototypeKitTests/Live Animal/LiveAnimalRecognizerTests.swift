//
//  LiveAnimalRecognizerTests.swift
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
final class LiveAnimalRecognizerTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    func testAnimalRecognizerViewInit() throws {
        let view = LiveAnimalRecognizerView()
        XCTAssertNoThrow(view.body)
    }

#if os(macOS)
    // A blank frame contains no animals, so the receiver should report an empty result
    // without crashing — this validates the request/publisher wiring.
    func testAnimalRecognizerBlankImageMac() throws {
        let receiver = LiveAnimalRecognizerReceiver()

        let cgImage = try makeSolidColorCGImage(width: 200, height: 200)

        receiver.processImage(cgImage)

        let expectation = XCTestExpectation(description: "No animals recognised in a blank frame")
        receiver.$detectedAnimals.sink { newValue in
            XCTAssertTrue(newValue.isEmpty,
                          "Expected no animals in a blank frame but received \(newValue)")
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 10)
    }
#endif
}
