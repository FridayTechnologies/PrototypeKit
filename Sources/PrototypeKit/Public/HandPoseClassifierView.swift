//
//  File.swift
//  
//
//  Created by James Dale on 5/6/2024.
//

import SwiftUI
import CoreML
import Vision

final class HandPoseClassifierReceiver: PKCameraViewReceiver, ObservableObject {
    
    private let mlModel: MLModel
    
    @Published var latestPrediction: String?
    
    private lazy var handPoseRequest = {
        let req = VNDetectHumanHandPoseRequest { request, error in
            guard
                let handRequest = request as? VNDetectHumanHandPoseRequest,
                let handposes = handRequest.results,
                let handObservation = handposes.first,
                let multiArray = try? handObservation.keypointsMultiArray(),
                let fp = try? MLDictionaryFeatureProvider(dictionary: [
                    "poses": multiArray
                ]),
                let prediction = try? self.mlModel.prediction(from: fp)
            else { return }
            
            if let label = prediction.featureValue(for: "label") {
                self.latestPrediction = label.stringValue
            }
            
        }
        req.revision = 1
        req.maximumHandCount = 1
        return req
    }()
    
    init(mlModel: MLModel) {
        self.mlModel = mlModel
    }
    
    func processImage(_ cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: .up,
                                            options: [:])
        
#if targetEnvironment(simulator)
        // Running in simulator
        handPoseRequest.usesCPUOnly = true
#endif
        
#if canImport(XCTest)
        // Running in XCTest
        handPoseRequest.usesCPUOnly = true
#endif
        
        try! handler.perform([handPoseRequest])
    }
}

public struct HandPoseClassifierView: View {
    
    @State var receiver: HandPoseClassifierReceiver
    
    @Binding var latestPrediction: String
    
    public init(modelURL: URL, latestPrediction: Binding<String> = .constant("")) {
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            self.receiver = HandPoseClassifierReceiver(mlModel: mlModel)
            self._latestPrediction = latestPrediction
        } catch {
            fatalError() // TODO: Make this prettier.
        }
    }
    
    public var body: some View {
        PKCameraView(receiver: receiver)
            .onReceive(receiver.$latestPrediction, perform: { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestPrediction = newPrediction
            })
    }
}
