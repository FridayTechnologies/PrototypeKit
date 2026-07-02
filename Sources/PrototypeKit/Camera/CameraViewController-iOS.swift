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
    public var cameraDeviceType: AVCaptureDevice.DeviceType
    
    init(cameraPosition: AVCaptureDevice.Position, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera) {
        self.cameraPosition = cameraPosition
        self.cameraDeviceType = cameraType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        // Surface a clear, on-screen message instead of a black preview when the host app hasn't
        // declared the camera usage description — a mistake that otherwise looks like a broken camera.
        guard checkDeveloperHasConfiguredInfoPlist() else {
            presentCenteredMessage(
                icon: "⚠️",
                text: NSLocalizedString("camera.missingUsageDescription",
                                        bundle: .module,
                                        comment: "Shown on the camera preview when NSCameraUsageDescription is missing."))
            return
        }
        #if targetEnvironment(simulator)
        checkAndHandleSimulator()
                return
        #endif
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
    
    func checkAndHandleSimulator() {
#if targetEnvironment(simulator)
        presentCenteredMessage(
            icon: "📸",
            text: NSLocalizedString("camera.unavailableInSimulator",
                                    bundle: .module,
                                    comment: "Shown in place of the camera preview in the Simulator and previews."))
#endif
    }

    /// Shows a centered icon and message in place of the camera preview.
    func presentCenteredMessage(icon: String, text: String) {
        view.backgroundColor = .gray

        let iconLabel = UILabel(frame: .zero)
        iconLabel.text = icon
        iconLabel.font = .preferredFont(forTextStyle: .largeTitle)

        let warningLabel = UILabel(frame: .zero)
        warningLabel.text = text
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [ iconLabel, warningLabel ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
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
        
        guard let videoDevice = AVCaptureDevice.default(cameraDeviceType,
                                                        for: .video,
                                                        position: cameraPosition)
        else { return }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        updatePreviewLayer()
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        self.previewLayer.connection?.pk_apply(.portrait)
        
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
            self.previewLayer.connection?.pk_apply(.portraitUpsideDown)
        case UIDeviceOrientation.landscapeLeft:
            self.previewLayer.connection?.pk_apply(.landscapeRight)
        case UIDeviceOrientation.landscapeRight:
            self.previewLayer.connection?.pk_apply(.landscapeLeft)
        case UIDeviceOrientation.portrait:
            self.previewLayer.connection?.pk_apply(.portrait)
        default:
            break
        }
    }
}

#endif
