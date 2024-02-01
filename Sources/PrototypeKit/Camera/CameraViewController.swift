//
//  CameraViewController.swift
//
//
//  Created by James Dale on 1/2/2024.
//

import UIKit
import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {
    
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var screenRect: CGRect! = nil
    
    override func viewDidLoad() {
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
    
    func requestPermission() {
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
        
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,
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
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayer()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
    
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0,
                                         y: 0,
                                         width: screenRect.size.width,
                                         height: screenRect.size.height)
        
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.portraitUpsideDown:
            self.previewLayer.connection?.videoOrientation = .portraitUpsideDown
        case UIDeviceOrientation.landscapeLeft:
            self.previewLayer.connection?.videoOrientation = .landscapeRight
        case UIDeviceOrientation.landscapeRight:
            self.previewLayer.connection?.videoOrientation = .landscapeLeft
        case UIDeviceOrientation.portrait:
            self.previewLayer.connection?.videoOrientation = .portrait
        default:
            break
        }
    }
}
