//
//  HandPoseClassifierView.swift
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

/// A SwiftUI view that shows a live camera feed and classifies hand poses using a Core ML model.
///
/// The view detects hand keypoints with Vision's `VNDetectHumanHandPoseRequest` and feeds them into the
/// Create ML / Core ML hand-action classifier you provide, publishing the predicted label through a binding.
/// It drives a ``PKCameraView`` internally, so your app target must declare the `NSCameraUsageDescription`
/// (Privacy - Camera Usage Description) key in its Info properties.
///
/// ```swift
/// @State var latestPrediction = ""
///
/// HandPoseClassifierView(modelURL: HandPoseClassifier.urlOfModelInThisBundle,
///                        latestPrediction: $latestPrediction)
/// ```
///
/// - Note: A single hand is classified at a time (`maximumHandCount = 1`).
public struct HandPoseClassifierView: View {

    @State var receiver: HandPoseClassifierReceiver

    @Binding var latestPrediction: String

    /// Creates a hand pose classifier view backed by a Core ML model.
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML hand-pose model to load, typically
    ///     `YourModel.urlOfModelInThisBundle`.
    ///   - latestPrediction: A binding updated with the most recent predicted hand-pose label. Defaults to a
    ///     constant empty string when you only need the on-screen camera feed.
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
