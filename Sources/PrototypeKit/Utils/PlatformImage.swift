//
//  PlatformImage.swift
//
//
//  Created by James Dale on 2/2/2024.
//

import Foundation

#if canImport(Cocoa)
import AppKit

public typealias NativeImage = NSImage
#endif

#if canImport(UIKit)
import UIKit

public typealias NativeImage = UIImage
#endif

struct PlatformImage {
    
    var imageData: Data
    
    var image: NativeImage? {
        NativeImage(data: imageData)
    }
}
