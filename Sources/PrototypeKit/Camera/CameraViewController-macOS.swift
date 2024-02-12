//
//  File.swift
//  
//
//  Created by James Dale on 10/2/2024.
//

#if canImport(AppKit)
import Foundation
import AppKit
import SwiftUI
import AVFoundation

class CameraViewController: NSViewController {
    
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var screenRect: CGRect! = nil
    
    override func viewDidLoad() {
        checkDeveloperHasConfiguredInfoPlist()
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    func checkDeveloperHasConfiguredInfoPlist() -> Bool {
        guard let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String else {
            print("⚠️⚠️⚠️ You need to set NSCameraUsageDescription. See Setup on https://github.com/FridayTechnologies/PrototypeKit on how to set this up. ⚠️⚠️⚠️")
            return false
        }
        return true
    }
    
    func requestPermission() {
        guard checkDeveloperHasConfiguredInfoPlist() else { return }
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        updatePreviewLayer()
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            if self?.view.layer == nil {
                print("No View Layer!")
            }
            self!.view.layer?.addSublayer(self!.previewLayer)
        }
    }
    
    override func viewDidLayout() {
        updatePreviewLayer()
    }
    
    func updatePreviewLayer() {
        DispatchQueue.main.async {
            self.screenRect = self.view.bounds
            self.previewLayer.frame = CGRect(x: 0,
                                             y: 0,
                                             width: self.screenRect.size.width,
                                             height: self.screenRect.size.height)
        }
    }
    
    func addOutput(_ output: AVCaptureOutput) {
        guard captureSession.canAddOutput(output) else { return }
        captureSession.beginConfiguration()
        captureSession.addOutput(output)
        captureSession.commitConfiguration()
    }
    
    override func viewWillTransition(to newSize: NSSize) {
        updatePreviewLayer()
        self.previewLayer.connection?.videoOrientation = .portrait
    }
}

#endif
