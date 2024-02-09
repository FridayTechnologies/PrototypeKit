//
//  CameraViewController.swift
//
//
//  Created by James Dale on 1/2/2024.
//

#if canImport(UIKit)
import UIKit
import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {
    
    private var permissionGranted = false
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "cameraSessionQueue")
    
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var screenRect: CGRect! = nil
    
    public var cameraPosition: AVCaptureDevice.Position
    
    init(cameraPosition: AVCaptureDevice.Position) {
        self.cameraPosition = cameraPosition
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        #if targetEnvironment(simulator)
        checkAndHandleSimulator()
                return
        #endif
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
    
    func checkAndHandleSimulator() {
#if targetEnvironment(simulator)
        view.backgroundColor = .gray
        
        let iconLabel = UILabel(frame: .zero)
        iconLabel.text = "📸"
        iconLabel.font = .preferredFont(forTextStyle: .largeTitle)
        
        let warningLabel = UILabel(frame: .zero)
        warningLabel.text = "Live camera is not supported in previews."
        
        let stackView = UIStackView(arrangedSubviews: [ iconLabel, warningLabel ])
        stackView.axis = .vertical
        stackView.alignment = .center
        
        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
#endif
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
                                                        position: cameraPosition)
        else { return }
        
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
        updatePreviewLayer()
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

#endif
