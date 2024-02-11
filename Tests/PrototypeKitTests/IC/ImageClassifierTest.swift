//
//  ImageClassifierTest.swift
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
final class ImageClassifierTest: XCTestCase {
    
    private var cancellables = [AnyCancellable]()

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testICViewInit() throws {
        let icView = ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle)
        XCTAssertNoThrow(icView.body)
    }

    #if os(macOS)
    func testICReceiverMac() throws {
        let mlModel = try MLModel(contentsOf: FruitClassifier.urlOfModelInThisBundle)
        let vnModel = try VNCoreMLModel(for: mlModel)
        let receiver = ImageClassifierReceiver(vnMLModel: vnModel)
        
        let imageURL = Bundle.module.url(forResource: "apple", withExtension: "jpeg")!
        guard
            let image = NSImage(contentsOf: imageURL),
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { fatalError("Sample image is not a valid CGImage")}
        
        receiver.processImage(cgImage)
        
        let expectedOutput = "apple"
        
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
    
    // FIXME: For context, the below function doesn't seem to work well on simulator.
//    func _FIXMEicReceiveriOSTest() throws {
//        let mlModel = try MLModel(contentsOf: FruitClassifier.urlOfModelInThisBundle)
//        let vnModel = try VNCoreMLModel(for: mlModel)
//        let receiver = ImageClassifierReceiver(vnMLModel: vnModel)
//        
//        let imageURL = Bundle.module.url(forResource: "banana", withExtension: "jpeg")!
//        let image = UIImage(contentsOf: imageURL)
//        guard let cgImage = image?.cgImage else { fatalError("No Sample Image") }
//        
//        receiver.processImage(cgImage)
//        
//        let expectedOutput = "banana"
//        
//        let expectation = XCTestExpectation(description: "The item is recognised")
//        receiver.$latestPrediction.sink { newValue in
//            if newValue == expectedOutput { expectation.fulfill() }
//            else {
//                XCTFail("The wrong item was recognised. Expected \(expectedOutput) but received \(newValue ?? "no value")")
//            }
//        }.store(in: &cancellables)
//        
//        wait(for: [expectation], timeout: 10)
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
