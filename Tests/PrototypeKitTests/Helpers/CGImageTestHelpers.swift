//
//  CGImageTestHelpers.swift
//
//
//  Synthetic CGImage builders for tests, so vision tests don't need bundled photo assets.
//

import XCTest
import CoreGraphics

enum CGImageTestError: Error {
    case couldNotCreateContext
    case couldNotCreateImage
}

private func makeBitmapContext(width: Int, height: Int) throws -> CGContext {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CGImageTestError.couldNotCreateContext
    }
    return context
}

/// Creates a solid-color (default black) `CGImage` — a blank frame containing no subjects.
func makeSolidColorCGImage(width: Int,
                           height: Int,
                           color: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)) throws -> CGImage {
    let context = try makeBitmapContext(width: width, height: height)
    context.setFillColor(color)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    guard let image = context.makeImage() else {
        throw CGImageTestError.couldNotCreateImage
    }
    return image
}

/// Creates a `CGImage` with a single high-contrast white rectangle centered on a black background,
/// suitable for exercising `VNDetectRectanglesRequest`.
func makeRectangleCGImage(width: Int = 400, height: Int = 400) throws -> CGImage {
    let context = try makeBitmapContext(width: width, height: height)
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let inset = CGRect(x: Double(width) * 0.2,
                       y: Double(height) * 0.2,
                       width: Double(width) * 0.6,
                       height: Double(height) * 0.6)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(inset)

    guard let image = context.makeImage() else {
        throw CGImageTestError.couldNotCreateImage
    }
    return image
}
