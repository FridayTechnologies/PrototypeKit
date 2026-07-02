//
//  CameraViewController-macOS.swift
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
        guard checkDeveloperHasConfiguredInfoPlist() else { return }
        checkPermission()

        sessionQueue.async { [weak self] in
            guard let self = self, self.permissionGranted else { return }
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
    
    @discardableResult
    func checkDeveloperHasConfiguredInfoPlist() -> Bool {
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") is String else {
            PKLog.camera.error(
                "Missing NSCameraUsageDescription. Add the \"Privacy - Camera Usage Description\" "
                + "key to your app's Info settings. "
                + "See https://github.com/FridayTechnologies/PrototypeKit for setup.")
            return false
        }
        return true
    }
    
    func requestPermission() {
        guard checkDeveloperHasConfiguredInfoPlist() else { return }
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        // Macs have no "back" camera; ask for the system default video device instead of a
        // position-specific one, which would return nil on most Macs.
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            PKLog.camera.error("No video capture device is available on this Mac.")
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        updatePreviewLayer()
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        self.previewLayer.connection?.pk_apply(.portrait)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let layer = self.view.layer else {
                PKLog.camera.error("Camera preview could not be shown: the host view has no backing layer.")
                return
            }
            layer.addSublayer(self.previewLayer)
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
        self.previewLayer.connection?.pk_apply(.portrait)
    }
}

#endif
