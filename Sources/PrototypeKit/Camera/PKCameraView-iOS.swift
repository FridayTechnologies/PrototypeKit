//
//  PKCameraView.swift
//
//
//  Created by James Dale on 1/2/2024.
//

#if canImport(UIKit)
import SwiftUI
import AVFoundation

public typealias CameraOptions = (position: AVCaptureDevice.Position,
                                  deviceType: AVCaptureDevice.DeviceType)

public struct PKCameraView: UIViewControllerRepresentable {
    
    @State var position: AVCaptureDevice.Position = .back
    @State var deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
    
    private var receiver: PKCameraViewReceiver?
    
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
                
                let context = CIContext(options: nil)
                
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    return
                }
                
                receiver?.processImage(cgImage)
            }
        }
    }
}
#endif
