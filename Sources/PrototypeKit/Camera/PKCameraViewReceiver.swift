//
//  File.swift
//  
//
//  Created by James Dale on 10/2/2024.
//

import CoreGraphics.CGImage

protocol PKCameraViewReceiver {
    func processImage(_ image: CGImage)
}
