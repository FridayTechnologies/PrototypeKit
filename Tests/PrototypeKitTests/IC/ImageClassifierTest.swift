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

    #if os(iOS)
    func testICReceiver() throws {
        let mlModel = try MLModel(contentsOf: FruitClassifier.urlOfModelInThisBundle)
        let vnModel = try VNCoreMLModel(for: mlModel)
        let receiver = ImageClassifierReceiver(vnMLModel: vnModel)
        
        let imageURL = Bundle.module.url(forResource: "banana", withExtension: "jpeg")!
        let image = UIImage(contentsOfFile: imageURL.path())
        guard let cgImage = image?.cgImage else { fatalError("No Sample Image") }
        
        receiver.processImage(cgImage)
        
        let expectation = XCTestExpectation(description: "The item is recognised")
        receiver.$latestPrediction.sink { newValue in
            if newValue == "apple" { expectation.fulfill() }
            else {
                XCTFail("The wrong item was recognised")
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
