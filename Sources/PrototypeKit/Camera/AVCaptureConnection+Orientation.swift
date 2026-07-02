//
//  AVCaptureConnection+Orientation.swift
//
//
//  Bridges the pre-iOS-17 `videoOrientation` API and the newer `videoRotationAngle` API.
//

import AVFoundation

extension AVCaptureConnection {

    /// Applies a video orientation to the connection.
    ///
    /// `videoOrientation` was deprecated in iOS 17 / macOS 14 in favor of `videoRotationAngle`
    /// (degrees, counter-clockwise). This helper uses the modern API where available and falls back
    /// to `videoOrientation` on earlier systems, so PrototypeKit stays forward-compatible while still
    /// supporting its iOS 14 / macOS 13 deployment targets.
    func pk_apply(_ orientation: AVCaptureVideoOrientation) {
        if #available(iOS 17.0, macOS 14.0, *) {
            let angle: CGFloat
            switch orientation {
            case .portrait: angle = 90
            case .portraitUpsideDown: angle = 270
            case .landscapeRight: angle = 0
            case .landscapeLeft: angle = 180
            @unknown default: angle = 90
            }
            guard isVideoRotationAngleSupported(angle) else { return }
            videoRotationAngle = angle
        } else {
            videoOrientation = orientation
        }
    }
}
