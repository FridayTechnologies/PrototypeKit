//
//  HandPoseClassifierViewTests.swift
//  
//
//  Created by James Dale on 5/6/2024.
//

import XCTest
import Vision
import Combine

@testable import PrototypeKit

final class HandPoseClassifierViewTests: XCTestCase {
    
    private var cancellables = [AnyCancellable]()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

#if os(macOS)
func testHPCReceiverMac() throws {
    let mlModel = try MLModel(contentsOf: HandPoseClassifier.urlOfModelInThisBundle)
    let receiver = HandPoseClassifierReceiver(mlModel: mlModel)
    
    let imageURL = Bundle.module.url(forResource: "force-expand",
                                     withExtension: "jpg")!
    guard
        let image = NSImage(contentsOf: imageURL),
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else { fatalError("Sample image is not a valid CGImage")}
    
    receiver.processImage(cgImage)
    
    let expectedOutput = "Expand"
    
    let expectation = XCTestExpectation(description: "The item is recognised")
    receiver.$latestPrediction.sink { newValue in
        guard let newValue = newValue else { return }
        if newValue == expectedOutput { expectation.fulfill() }
        else {
            XCTFail("The wrong item was recognised. Expected \(expectedOutput) but received \(newValue)")
        }
    }.store(in: &cancellables)
    
    wait(for: [expectation], timeout: 10)
}
#endif

}
