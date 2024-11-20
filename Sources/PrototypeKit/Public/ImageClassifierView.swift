//
//  ImageClassifierView.swift
//
//
//  Created by James Dale on 1/2/2024.
//

import SwiftUI
import CoreML
import Vision

final class ImageClassifierReceiver: PKCameraViewReceiver, ObservableObject {
    
    private let vnCoreMLModel: VNCoreMLModel
    
    @Published var latestPrediction: String?
    
    private lazy var request = VNCoreMLRequest(model: self.vnCoreMLModel) { request, error in
        guard let observation = request.results?.first as? VNClassificationObservation else {
            return
        }
        DispatchQueue.main.async {
            self.latestPrediction = observation.identifier
            print("Predicted: ", observation.identifier)
        }
    }
    
    init(vnMLModel: VNCoreMLModel) {
        self.vnCoreMLModel = vnMLModel
    }
    
    func processImage(_ cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])
        
#if targetEnvironment(simulator)
        // Running in simulator
        request.usesCPUOnly = true
#endif
        
#if canImport(XCTest)
        // Running in XCTest
        request.usesCPUOnly = true
#endif
        request.imageCropAndScaleOption = .centerCrop
        try! handler.perform([request])
    }
}

public struct ImageClassifierView: View {
    
    @State var receiver: ImageClassifierReceiver
    
    @Binding var latestPrediction: String
    
    private let cameraOptions: CameraOptions?
    
    public init(modelURL: URL,
                latestPrediction: Binding<String> = .constant(""),
                camera: CameraOptions? = nil) {
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let vnModel = try VNCoreMLModel(for: mlModel)
            self.receiver = ImageClassifierReceiver(vnMLModel: vnModel)
            self._latestPrediction = latestPrediction
            self.cameraOptions = camera
        } catch {
            fatalError() // TODO: Make this prettier.
        }
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver, options: cameraOptions)
            .onReceive(receiver.$latestPrediction, perform: { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestPrediction = newPrediction
            })
    }
}
