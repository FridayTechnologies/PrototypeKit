//
//  LiveTextRecognizerTests.swift
//
//
//  Created by James Dale on 9/2/2024.
//

import XCTest
import Vision
import CoreML
import Combine

@testable
import PrototypeKit

@available(iOS 16.0, *)
final class LiveTextRecognizerTests: XCTestCase {
    
    private var cancellables = [AnyCancellable]()

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

#if os(macOS)
    func testLiveTextRecognizerMac() throws {
        let receiver = LiveTextRecognizerReceiver()
        
        let imageURL = Bundle.module.url(forResource: "sampleText",
                                         withExtension: "png")!
        guard
            let image = NSImage(contentsOf: imageURL),
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { fatalError("Sample image is not a valid CGImage")}
        
        receiver.processImage(cgImage)
        
        let expectedOutput = ["PrototypeKit Sample Text"]
        
        let expectation = XCTestExpectation(description: "The text is recognised")
        receiver.$detectedText.sink { newValue in
            guard !newValue.isEmpty else { return }
            if newValue == expectedOutput { expectation.fulfill() }
            else {
                XCTFail("The wrong item was recognised. Expected \(expectedOutput) but received \(newValue)")
            }
        }.store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10)
    }
#endif

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
