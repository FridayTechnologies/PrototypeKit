//
//  ActivityClassifierView.swift
//
//
//  Created by James Dale on 1/7/2026.
//

#if os(iOS)
import Foundation
import SwiftUI
import CoreML
import CoreMotion

/// Configuration options for live activity classification via ``ActivityClassifierView``.
///
/// The defaults match the input and output feature names produced by a standard Create ML
/// **Activity Classifier**, which is trained on device-motion (accelerometer + gyroscope) data.
/// If your model uses different feature names, override them here so they line up with your model.
public struct ActivityClassifierConfiguration {

    /// How often, in seconds, the accelerometer and gyroscope are sampled.
    ///
    /// This should match the sample rate the model was trained at. Create ML's Activity Classifier
    /// template records at 50 Hz by default, hence `1 / 50`.
    var sensorUpdateInterval: Double

    /// The number of samples that inform a single prediction.
    ///
    /// This must match the model's prediction window. When the model advertises a fixed input window,
    /// ``ActivityClassifierView`` uses the model's value; otherwise it falls back to this one.
    var predictionWindowSize: Int

    /// The model input feature name for accelerometer data on the X axis.
    var accelerometerXFeatureName: String
    /// The model input feature name for accelerometer data on the Y axis.
    var accelerometerYFeatureName: String
    /// The model input feature name for accelerometer data on the Z axis.
    var accelerometerZFeatureName: String

    /// The model input feature name for gyroscope rotation rate on the X axis.
    var gyroscopeXFeatureName: String
    /// The model input feature name for gyroscope rotation rate on the Y axis.
    var gyroscopeYFeatureName: String
    /// The model input feature name for gyroscope rotation rate on the Z axis.
    var gyroscopeZFeatureName: String

    /// The model input feature name for the recurrent state fed back between predictions.
    var stateInFeatureName: String
    /// The model output feature name for the recurrent state produced by a prediction.
    var stateOutFeatureName: String
    /// The model output feature name for the predicted activity label.
    var labelFeatureName: String

    /// Creates an activity classifier configuration.
    ///
    /// - Parameters:
    ///   - sensorUpdateInterval: How often, in seconds, to sample the sensors. Should match the
    ///     model's training sample rate. Defaults to `1 / 50` (50 Hz).
    ///   - predictionWindowSize: The number of samples per prediction. Used only when the model does
    ///     not advertise a fixed input window. Defaults to `50`.
    ///   - accelerometerXFeatureName: Accelerometer X input feature name. Defaults to `"accelerometerAccelerationX"`.
    ///   - accelerometerYFeatureName: Accelerometer Y input feature name. Defaults to `"accelerometerAccelerationY"`.
    ///   - accelerometerZFeatureName: Accelerometer Z input feature name. Defaults to `"accelerometerAccelerationZ"`.
    ///   - gyroscopeXFeatureName: Gyroscope X input feature name. Defaults to `"gyroRotationX"`.
    ///   - gyroscopeYFeatureName: Gyroscope Y input feature name. Defaults to `"gyroRotationY"`.
    ///   - gyroscopeZFeatureName: Gyroscope Z input feature name. Defaults to `"gyroRotationZ"`.
    ///   - stateInFeatureName: Recurrent state input feature name. Defaults to `"stateIn"`.
    ///   - stateOutFeatureName: Recurrent state output feature name. Defaults to `"stateOut"`.
    ///   - labelFeatureName: Predicted label output feature name. Defaults to `"label"`.
    public init(sensorUpdateInterval: Double = 1.0 / 50.0,
                predictionWindowSize: Int = 50,
                accelerometerXFeatureName: String = "accelerometerAccelerationX",
                accelerometerYFeatureName: String = "accelerometerAccelerationY",
                accelerometerZFeatureName: String = "accelerometerAccelerationZ",
                gyroscopeXFeatureName: String = "gyroRotationX",
                gyroscopeYFeatureName: String = "gyroRotationY",
                gyroscopeZFeatureName: String = "gyroRotationZ",
                stateInFeatureName: String = "stateIn",
                stateOutFeatureName: String = "stateOut",
                labelFeatureName: String = "label") {
        self.sensorUpdateInterval = sensorUpdateInterval
        self.predictionWindowSize = predictionWindowSize
        self.accelerometerXFeatureName = accelerometerXFeatureName
        self.accelerometerYFeatureName = accelerometerYFeatureName
        self.accelerometerZFeatureName = accelerometerZFeatureName
        self.gyroscopeXFeatureName = gyroscopeXFeatureName
        self.gyroscopeYFeatureName = gyroscopeYFeatureName
        self.gyroscopeZFeatureName = gyroscopeZFeatureName
        self.stateInFeatureName = stateInFeatureName
        self.stateOutFeatureName = stateOutFeatureName
        self.labelFeatureName = labelFeatureName
    }
}

final class ActivityClassifierReceiver: ObservableObject {

    /// Rolling buffers of raw sensor samples, one per axis.
    ///
    /// Allocated together so the receiver is either fully ready to classify or not at all.
    private struct SensorBuffers {
        let accelerometerX: MLMultiArray
        let accelerometerY: MLMultiArray
        let accelerometerZ: MLMultiArray
        let gyroscopeX: MLMultiArray
        let gyroscopeY: MLMultiArray
        let gyroscopeZ: MLMultiArray

        init?(windowSize: Int) {
            let shape = [NSNumber(value: windowSize)]
            guard
                let accelerometerX = try? MLMultiArray(shape: shape, dataType: .double),
                let accelerometerY = try? MLMultiArray(shape: shape, dataType: .double),
                let accelerometerZ = try? MLMultiArray(shape: shape, dataType: .double),
                let gyroscopeX = try? MLMultiArray(shape: shape, dataType: .double),
                let gyroscopeY = try? MLMultiArray(shape: shape, dataType: .double),
                let gyroscopeZ = try? MLMultiArray(shape: shape, dataType: .double)
            else { return nil }
            self.accelerometerX = accelerometerX
            self.accelerometerY = accelerometerY
            self.accelerometerZ = accelerometerZ
            self.gyroscopeX = gyroscopeX
            self.gyroscopeY = gyroscopeY
            self.gyroscopeZ = gyroscopeZ
        }
    }

    private let mlModel: MLModel?
    private let configuration: ActivityClassifierConfiguration
    private let motionManager = CMMotionManager()

    @Published var latestPrediction: String?

    /// The number of samples that make up one prediction window.
    private let windowSize: Int

    /// The sensor sample buffers, or `nil` when the model failed to load or buffers could not be allocated.
    private let buffers: SensorBuffers?

    /// The recurrent state carried between predictions, if the model uses one.
    private var stateIn: MLMultiArray?

    /// How many samples we've written into the current window.
    private var sampleCount = 0

    private var timer: Timer?

    /// Creates a receiver for the given activity model.
    ///
    /// - Parameters:
    ///   - mlModel: The Core ML activity-classification model, or `nil` when the model failed to load.
    ///     When `nil`, sampling never starts and no predictions are published.
    ///   - configuration: The sensor and feature-name configuration.
    init(mlModel: MLModel?, configuration: ActivityClassifierConfiguration) {
        self.mlModel = mlModel
        self.configuration = configuration

        let inputs = mlModel?.modelDescription.inputDescriptionsByName ?? [:]

        // Prefer the model's own window size when it advertises one, so the buffers always match.
        let modelWindowSize = inputs[configuration.accelerometerXFeatureName]?
            .multiArrayConstraint?.shape.last?.intValue
        let resolvedWindowSize = modelWindowSize ?? configuration.predictionWindowSize
        self.windowSize = resolvedWindowSize

        self.buffers = mlModel == nil ? nil : SensorBuffers(windowSize: resolvedWindowSize)

        // Allocate the recurrent state buffer (zero-filled) only if the model expects one.
        if let stateConstraint = inputs[configuration.stateInFeatureName]?.multiArrayConstraint,
           let state = try? MLMultiArray(shape: stateConstraint.shape, dataType: stateConstraint.dataType) {
            for i in 0..<state.count {
                state[i] = 0
            }
            self.stateIn = state
        }
    }

    /// Begins sampling the accelerometer and gyroscope and classifying activity.
    func start() {
        guard mlModel != nil, buffers != nil else { return }
        guard motionManager.isAccelerometerAvailable, motionManager.isGyroAvailable else { return }
        guard timer == nil else { return }

        sampleCount = 0
        motionManager.accelerometerUpdateInterval = configuration.sensorUpdateInterval
        motionManager.gyroUpdateInterval = configuration.sensorUpdateInterval
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()

        let timer = Timer(timeInterval: configuration.sensorUpdateInterval, repeats: true) { [weak self] _ in
            self?.sample()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Stops sampling and releases the sensors.
    func stop() {
        timer?.invalidate()
        timer = nil
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }

    /// Reads the latest synchronized accelerometer and gyroscope values into the buffers,
    /// running a prediction once a full window has been collected.
    private func sample() {
        guard let buffers = buffers else { return }
        guard let accelerometer = motionManager.accelerometerData,
              let gyroscope = motionManager.gyroData else { return }

        buffers.accelerometerX[sampleCount] = NSNumber(value: accelerometer.acceleration.x)
        buffers.accelerometerY[sampleCount] = NSNumber(value: accelerometer.acceleration.y)
        buffers.accelerometerZ[sampleCount] = NSNumber(value: accelerometer.acceleration.z)
        buffers.gyroscopeX[sampleCount] = NSNumber(value: gyroscope.rotationRate.x)
        buffers.gyroscopeY[sampleCount] = NSNumber(value: gyroscope.rotationRate.y)
        buffers.gyroscopeZ[sampleCount] = NSNumber(value: gyroscope.rotationRate.z)

        sampleCount += 1

        if sampleCount == windowSize {
            sampleCount = 0
            predict()
        }
    }

    /// Runs the model over the current window and publishes the predicted label.
    private func predict() {
        guard let mlModel = mlModel, let buffers = buffers else { return }

        var features: [String: Any] = [
            configuration.accelerometerXFeatureName: buffers.accelerometerX,
            configuration.accelerometerYFeatureName: buffers.accelerometerY,
            configuration.accelerometerZFeatureName: buffers.accelerometerZ,
            configuration.gyroscopeXFeatureName: buffers.gyroscopeX,
            configuration.gyroscopeYFeatureName: buffers.gyroscopeY,
            configuration.gyroscopeZFeatureName: buffers.gyroscopeZ
        ]
        if let stateIn = stateIn {
            features[configuration.stateInFeatureName] = stateIn
        }

        guard let featureProvider = try? MLDictionaryFeatureProvider(dictionary: features),
              let prediction = try? mlModel.prediction(from: featureProvider) else { return }

        // Feed the recurrent state back in for the next window.
        if let stateOut = prediction.featureValue(for: configuration.stateOutFeatureName)?.multiArrayValue {
            stateIn = stateOut
        }

        if let label = prediction.featureValue(for: configuration.labelFeatureName)?.stringValue {
            DispatchQueue.main.async {
                self.latestPrediction = label
            }
        }
    }

    deinit {
        stop()
    }
}

extension View {
    /// Classifies the device's physical activity in real-time from the accelerometer and gyroscope.
    ///
    /// Attach this modifier to any view to begin activity classification. It samples the accelerometer and
    /// gyroscope with `CoreMotion` and feeds the readings into the Create ML / Core ML **Activity
    /// Classifier** you provide, updating a binding with the most recent predicted label. Like sound
    /// recognition, it produces no visible content of its own — it drives classification while the view it
    /// is attached to is on screen.
    ///
    /// Sampling starts when the view appears and stops when it disappears.
    ///
    /// ```swift
    /// @State var latestActivity: String?
    ///
    /// Text(latestActivity ?? "Detecting…")
    ///     .classifyActivity(modelURL: ActivityClassifier.urlOfModelInThisBundle,
    ///                       latestActivity: $latestActivity)
    /// ```
    ///
    /// - Parameters:
    ///   - modelURL: The location of the compiled Core ML / Create ML activity-classification model to
    ///     load, typically `YourModel.urlOfModelInThisBundle`.
    ///   - configuration: An ``ActivityClassifierConfiguration`` describing the sensor sample rate and the
    ///     model's feature names. Defaults match a standard Create ML Activity Classifier.
    ///   - latestActivity: A binding updated with the most recently predicted activity label, or `nil`
    ///     when nothing has been classified yet.
    /// - Returns: A view that classifies activity while visible.
    /// - Important: Activity classification relies on `CoreMotion` and is available on iOS only.
    public func classifyActivity(modelURL: URL,
                                 configuration: ActivityClassifierConfiguration = .init(),
                                 latestActivity: Binding<String?>) -> some View {
        modifier(ClassifyActivityModifier(modelURL: modelURL,
                                          configuration: configuration,
                                          latestActivity: latestActivity))
    }
}

struct ClassifyActivityModifier: ViewModifier {

    @StateObject private var receiver: ActivityClassifierReceiver

    @Binding var latestActivity: String?

    init(modelURL: URL,
         configuration: ActivityClassifierConfiguration,
         latestActivity: Binding<String?>) {
        self._latestActivity = latestActivity
        let loadedModel: MLModel?
        do {
            loadedModel = try MLModel(contentsOf: modelURL)
        } catch {
            // Degrade gracefully: the modifier stays inert rather than crashing the host app
            // when the model can't be loaded.
            PKLog.model.error("Failed to load activity model at \(modelURL.path): \(error.localizedDescription)")
            loadedModel = nil
        }
        self._receiver = StateObject(wrappedValue: ActivityClassifierReceiver(mlModel: loadedModel,
                                                                              configuration: configuration))
    }

    func body(content: Content) -> some View {
        content
            .onAppear { receiver.start() }
            .onDisappear { receiver.stop() }
            .onReceive(receiver.$latestPrediction) { newPrediction in
                guard let newPrediction = newPrediction else { return }
                self.latestActivity = newPrediction
            }
    }
}
#endif
