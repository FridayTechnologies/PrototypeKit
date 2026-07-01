//
//  PKCameraViewReceiver.swift
//
//
//  Created by James Dale on 10/2/2024.
//

import CoreGraphics.CGImage

/// A type that receives camera frames from a ``PKCameraView`` for processing.
///
/// Conformers implement ``processImage(_:)`` to run vision or Core ML work on each captured frame.
protocol PKCameraViewReceiver {
    func processImage(_ image: CGImage)
}
