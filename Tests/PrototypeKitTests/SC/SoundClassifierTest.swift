//
//  File.swift
//  
//
//  Created by James Dale on 5/6/2024.
//

import Foundation
import XCTest
import CoreML
import SwiftUI

@testable
import PrototypeKit

@available(iOS 16.0, *)
final class SoundClassifierTest: XCTestCase {
    
#if os(iOS)
    func testSoundClassifierModifierInit() {
        let someView = Rectangle()
        XCTAssertNoThrow(someView.recognizeSounds(recognizedSound: .constant(nil)))
    }
#endif
    
#if os(iOS)
    func testSoundClassifierModifierCustomModelInit() {
        let someView = Rectangle()
        XCTAssertNoThrow(someView.recognizeSounds(recognizedSound: .constant(nil),
                                                  configuration: .init(mlModel: nil)))
    }
#endif
    
#if os(iOS)
    func testSoundClassifierModifierClassify() {
        let someView = Rectangle()
        XCTAssertNoThrow(someView.recognizeSounds(recognizedSound: .constant(nil)))
    }
#endif
    
}
