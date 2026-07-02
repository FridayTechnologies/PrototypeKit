//
//  PrototypeKitExamples.swift
//
//  Reference examples for PrototypeKit. Copy this file into your own SwiftUI app target.
//  This file is intentionally NOT part of the Swift package (it lives under Examples/), so it is
//  never compiled by the library — it's a copy-paste starting point.
//
//  Set `ExampleGallery()` as your app's root view. See Examples/README.md for the Info.plist keys
//  each feature needs (camera / microphone).
//

#if os(iOS)
import SwiftUI
import PrototypeKit

/// A menu linking to a demo for each PrototypeKit feature.
struct ExampleGallery: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Camera + Vision") {
                    NavigationLink("Live text", destination: LiveTextExample())
                    NavigationLink("Live barcodes", destination: LiveBarcodeExample())
                    NavigationLink("Face detection", destination: FaceCountExample())
                    NavigationLink("Image classification", destination: ImageClassifierExample())
                    NavigationLink("Object detection", destination: ObjectDetectorExample())
                    NavigationLink("Object detection (boxes)", destination: ObjectDetectorBoxesExample())
                    NavigationLink("Action classification", destination: ActionClassifierExample())
                }
                Section("Sound") {
                    NavigationLink("Sound recognition", destination: SoundExample())
                }
                Section("Motion") {
                    NavigationLink("Activity classification", destination: ActivityExample())
                }
                Section("Natural Language") {
                    NavigationLink("Sentiment", destination: SentimentExample())
                }
            }
            .navigationTitle("PrototypeKit")
        }
    }
}

// MARK: - Camera + Vision (no model required)

/// Recognizes text in the live camera feed and lists it.
struct LiveTextExample: View {
    @State private var detectedText: [String] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            LiveTextRecognizerView(detectedText: $detectedText)
            Text(detectedText.joined(separator: "\n"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
        }
        .ignoresSafeArea()
    }
}

/// Decodes barcodes/QR codes in the live camera feed.
struct LiveBarcodeExample: View {
    @State private var barcodes: [String] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            LiveBarcodeRecognizerView(detectedBarcodes: $barcodes)
            Text(barcodes.first ?? "Point the camera at a barcode")
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
        }
        .ignoresSafeArea()
    }
}

/// Counts faces in the live camera feed.
struct FaceCountExample: View {
    @State private var faceCount = 0

    var body: some View {
        ZStack(alignment: .top) {
            LiveFaceDetectorView(faceCount: $faceCount)
            Text("Faces: \(faceCount)")
                .font(.title2.bold())
                .padding()
                .background(.thinMaterial, in: Capsule())
                .padding(.top, 60)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Camera + Core ML (bring your own Create ML model)

/// Classifies each camera frame with a Create ML image classifier.
///
/// Replace `modelURL` with your own model, e.g. `FruitClassifier.urlOfModelInThisBundle`.
struct ImageClassifierExample: View {
    @State private var prediction = ""
    @State private var errorMessage: String?

    // Point this at your Create ML model's `urlOfModelInThisBundle`.
    private let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")

    var body: some View {
        ZStack(alignment: .bottom) {
            ImageClassifierView(modelURL: modelURL,
                                latestPrediction: $prediction) { error in
                // React to a model-load failure instead of showing a silent, prediction-less feed.
                errorMessage = error.localizedDescription
            }
            Text(errorMessage ?? (prediction.isEmpty ? "Classifying…" : prediction))
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
        }
        .ignoresSafeArea()
    }
}

/// Detects objects in each camera frame with a Create ML object detector.
///
/// Replace `modelURL` with your own model, e.g. `MyObjectDetector.urlOfModelInThisBundle`.
struct ObjectDetectorExample: View {
    @State private var detectedObjects: [String] = []
    @State private var errorMessage: String?

    // Point this at your Create ML object detector's `urlOfModelInThisBundle`.
    private let modelURL = URL(fileURLWithPath: "/path/to/YourObjectDetector.mlmodelc")

    var body: some View {
        ZStack(alignment: .bottom) {
            ObjectDetectorView(modelURL: modelURL,
                               detectedObjects: $detectedObjects) { error in
                // React to a model-load failure instead of showing a silent, detection-less feed.
                errorMessage = error.localizedDescription
            }
            Text(errorMessage ?? (detectedObjects.isEmpty ? "Detecting…" : detectedObjects.joined(separator: ", ")))
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
        }
        .ignoresSafeArea()
    }
}

/// Detects objects and draws a bounding box + label around each one.
///
/// Replace `modelURL` with your own model, e.g. `MyObjectDetector.urlOfModelInThisBundle`.
struct ObjectDetectorBoxesExample: View {
    @State private var detectedObjects: [DetectedObject] = []
    @State private var errorMessage: String?

    private let modelURL = URL(fileURLWithPath: "/path/to/YourObjectDetector.mlmodelc")

    var body: some View {
        ZStack {
            ObjectDetectorView(modelURL: modelURL,
                               detectedObjects: $detectedObjects) { error in
                errorMessage = error.localizedDescription
            }

            GeometryReader { geometry in
                ForEach(Array(detectedObjects.enumerated()), id: \.offset) { _, object in
                    let box = object.boundingBox
                    Rectangle()
                        .stroke(.red, lineWidth: 2)
                        // Vision's origin is bottom-left; SwiftUI's is top-left, so flip Y.
                        .frame(width: box.width * geometry.size.width,
                               height: box.height * geometry.size.height)
                        .position(x: box.midX * geometry.size.width,
                                  y: (1 - box.midY) * geometry.size.height)
                        .overlay(
                            Text(object.label)
                                .font(.caption2)
                                .padding(2)
                                .background(.red)
                                .foregroundStyle(.white)
                                .position(x: box.midX * geometry.size.width,
                                          y: (1 - box.maxY) * geometry.size.height)
                        )
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundStyle(.red).padding().background(.thinMaterial)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Sound

/// Recognizes sounds from the microphone using the built-in classifier.
struct SoundExample: View {
    @State private var recognizedSound: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(recognizedSound ?? "Listening…")
                .font(.title)
            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }
        }
        .recognizeSounds(recognizedSound: $recognizedSound) { error in
            errorMessage = error.localizedDescription
        }
    }
}

/// Classifies a person's action from their body movement with a Create ML action classifier.
///
/// Replace `modelURL` with your own model, e.g. `ActionClassifier.urlOfModelInThisBundle`.
struct ActionClassifierExample: View {
    @State private var latestPrediction = ""
    @State private var errorMessage: String?

    private let modelURL = URL(fileURLWithPath: "/path/to/YourActionClassifier.mlmodelc")

    var body: some View {
        VStack(spacing: 16) {
            ActionClassifierView(modelURL: modelURL, latestPrediction: $latestPrediction) { error in
                errorMessage = error.localizedDescription
            }
            Text(latestPrediction.isEmpty ? "Detecting…" : latestPrediction).font(.title)
            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }
        }
    }
}

// MARK: - Motion

/// Classifies device activity with a Create ML activity classifier.
///
/// Replace `modelURL` with your own model, e.g. `ActivityClassifier.urlOfModelInThisBundle`.
struct ActivityExample: View {
    @State private var activity: String?
    @State private var errorMessage: String?

    private let modelURL = URL(fileURLWithPath: "/path/to/YourActivityModel.mlmodelc")

    var body: some View {
        VStack(spacing: 16) {
            Text(activity ?? "Detecting…").font(.title)
            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }
        }
        .classifyActivity(modelURL: modelURL, latestActivity: $activity) { error in
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Natural Language (ships with the OS, no camera/mic/model)

/// Scores the sentiment of some text as you type.
struct SentimentExample: View {
    @State private var text = "I love prototyping with this!"
    @State private var score: Double = 0

    var body: some View {
        Form {
            TextField("Type something", text: $text, axis: .vertical)
            Text("Sentiment: \(score, specifier: "%.2f")")
                .analyzeSentiment(text: text, score: $score)
        }
    }
}
#endif
