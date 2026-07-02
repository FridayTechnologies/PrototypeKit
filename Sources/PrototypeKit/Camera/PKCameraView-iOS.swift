//
//  PKCameraView.swift
//
//
//  Created by James Dale on 1/2/2024.
//


import SwiftUI
import AVFoundation

/// Options describing which camera to use.
///
/// - `position`: The camera position, e.g. `.front` or `.back`.
/// - `deviceType`: The capture device type, e.g. `.builtInWideAngleCamera`.
///
/// - Note: Camera options are ignored on macOS.
public typealias CameraOptions = (position: AVCaptureDevice.Position,
                                  deviceType: AVCaptureDevice.DeviceType)

#if canImport(UIKit)
/// A SwiftUI view that displays a live camera preview.
///
/// Use `PKCameraView()` on its own to show the device camera, or let the higher-level views
/// (such as ``ImageClassifierView`` and ``LiveTextRecognizerView``) drive it for you. Your app target must
/// declare the `NSCameraUsageDescription` (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// PKCameraView()
/// ```
///
/// - Note: The live camera is unavailable in the simulator and Xcode previews, where a placeholder is shown.
public struct PKCameraView: UIViewControllerRepresentable {

    @State var position: AVCaptureDevice.Position = .back
    @State var deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera

    private var receiver: PKCameraViewReceiver?

    /// Creates a camera view that displays the default back wide-angle camera preview.
    public init() {}
    
    init(receiver: PKCameraViewReceiver, options: CameraOptions? = nil) {
        self.receiver = receiver
        if let options = options {
            self.position = options.position
            self.deviceType = options.deviceType
        }
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.cameraViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self, receiver: receiver)
        coordinator.setupReceiver()
        return coordinator
    }
    
    public class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
        var cameraView: PKCameraView
        
        var receiver: PKCameraViewReceiver?
        
        var cameraViewController: CameraViewController
        
        private let receiverQueue = DispatchQueue(label: "receiverQueue")

        /// Reused across frames — creating a `CIContext` per frame is expensive and defeats its caching.
        private let ciContext = CIContext(options: nil)

        init(_ cameraView: PKCameraView, receiver: PKCameraViewReceiver?) {
            self.cameraView = cameraView
            self.receiver = receiver
            self.cameraViewController = CameraViewController(cameraPosition: cameraView.position,
                                                             cameraType: cameraView.deviceType)
        }
        
        func setupReceiver() {
            guard receiver != nil else { return }
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: receiverQueue)
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            cameraViewController.addOutput(output)
        }
        
        public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
            if let imageBuffer = sampleBuffer.imageBuffer {
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)

                guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                    return
                }

                receiver?.processImage(cgImage)
            }
        }
    }
}
#endif
