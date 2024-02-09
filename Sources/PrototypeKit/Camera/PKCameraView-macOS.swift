//
//  File.swift
//  
//
//  Created by James Dale on 10/2/2024.
//

#if os(macOS)
import SwiftUI
import AVFoundation

public struct PKCameraView: NSViewControllerRepresentable {
    
    private var receiver: PKCameraViewReceiver?
    
    public init() {}
    
    init(receiver: PKCameraViewReceiver) {
        self.receiver = receiver
    }
    
    public func makeNSViewController(context: Context) -> NSViewController {
        context.coordinator.cameraViewController
    }
    
    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self, receiver: receiver)
        coordinator.setupReceiver()
        return coordinator
    }
    
    public class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
        var cameraView: PKCameraView
        
        var receiver: PKCameraViewReceiver?
        
        var cameraViewController = CameraViewController()
        
        private let receiverQueue = DispatchQueue(label: "receiverQueue")
        
        init(_ cameraView: PKCameraView, receiver: PKCameraViewReceiver?) {
            self.cameraView = cameraView
            self.receiver = receiver
        }
        
        func setupReceiver() {
            guard receiver != nil else { return }
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: receiverQueue)
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
