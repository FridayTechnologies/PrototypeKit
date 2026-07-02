---
name: prototypekit
description: >-
  Reference and code-generation guide for PrototypeKit, a SwiftUI framework for
  rapid on-device machine-learning prototyping on iOS/macOS. Use whenever the
  user is building with PrototypeKit or asks for a live camera feed, on-device
  image classification, object detection, live text/OCR recognition, barcode
  scanning, animal recognition, face detection, body pose detection, rectangle
  detection, hand-pose
  classification, sound recognition, or natural-language analysis (sentiment,
  language identification, named-entity recognition) in a SwiftUI app. Provides exact
  initializer signatures, @State/@Binding wiring, required Info.plist privacy
  keys, and Core ML model setup.
---

# PrototypeKit

PrototypeKit wraps Vision, AVFoundation, SoundAnalysis, and Core ML behind a
handful of drop-in SwiftUI views and one view modifier, so you can prototype
on-device ML apps quickly. It is intentionally a simplified interface — great for
idea validation, not for production.

- **Platforms:** iOS 14+ and macOS 13+ (some features are iOS-only — see below).
- **Import:** `import PrototypeKit`
- **Distribution:** Swift Package Manager.

Always use the exact signatures in this document — do not invent parameters.

## Installation (Swift Package Manager)

In Xcode: **File ▸ Add Package Dependencies…** and enter
`https://github.com/FridayTechnologies/PrototypeKit`.

Or in a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/FridayTechnologies/PrototypeKit", branch: "master")
],
targets: [
    .target(name: "MyApp", dependencies: ["PrototypeKit"])
]
```

Then `import PrototypeKit` in any file that uses it.

## Required Info.plist permissions (most common cause of crashes)

Any camera-based view (`PKCameraView`, `ImageClassifierView`, `ObjectDetectorView`,
`LiveTextRecognizerView`, `LiveBarcodeRecognizerView`, `LiveAnimalRecognizerView`,
`LiveFaceDetectorView`, `LiveBodyPoseDetectorView`, `LiveRectangleDetectorView`,
`HandPoseClassifierView`) requires a camera-usage description, or the app crashes on
launch of that view:

- **Camera:** key `NSCameraUsageDescription` — shown in Xcode's Info tab as
  `Privacy - Camera Usage Description`. Value: a human-readable reason.

The sound modifier requires microphone access:

- **Microphone:** key `NSMicrophoneUsageDescription` —
  `Privacy - Microphone Usage Description`.

To add: select the project ▸ your target ▸ **Info** tab ▸ right-click the
"Custom iOS Target Properties" table ▸ **Add Row** ▸ pick the key ▸ type the reason.

## Core ML models

Views that classify or detect (`ImageClassifierView`, `ObjectDetectorView`,
`HandPoseClassifierView`) take a `modelURL: URL` pointing at a compiled Core ML model.

1. Drag your `.mlmodel` (from Create ML / Core ML) into the Xcode project.
2. Xcode generates a Swift class named after the model.
3. Pass its bundled URL, e.g. `FruitClassifier.urlOfModelInThisBundle`.

## API reference

### `PKCameraView` — raw live camera feed

```swift
PKCameraView()
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct ContentView: View {
    var body: some View {
        VStack {
            PKCameraView()
        }
        .padding()
    }
}
```

### `ImageClassifierView` — live image classification (Core ML)

Signature:

```swift
public init(modelURL: URL,
            latestPrediction: Binding<String> = .constant(""),
            camera: CameraOptions? = nil)
```

`CameraOptions` is a typealias:

```swift
public typealias CameraOptions = (position: AVCaptureDevice.Position,
                                  deviceType: AVCaptureDevice.DeviceType)
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct ImageClassifierViewSample: View {
    @State var latestPrediction: String = ""

    var body: some View {
        VStack {
            ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle,
                                latestPrediction: $latestPrediction)
            Text(latestPrediction)
        }
    }
}
```

### `ObjectDetectorView` — live object detection (Core ML)

Runs a Create ML / Core ML **Object Detector** model on each camera frame and publishes the
objects found. There are two initializers — pick by whether you need only *what* was detected or
also *where*:

```swift
// Labels only:
public init(modelURL: URL,
            detectedObjects: Binding<[String]> = .constant([]),
            camera: CameraOptions? = nil,
            onError: ((PrototypeKitError) -> Void)? = nil)

// Labels + confidence + bounding boxes:
public init(modelURL: URL,
            detectedObjects: Binding<[DetectedObject]>,
            camera: CameraOptions? = nil,
            onError: ((PrototypeKitError) -> Void)? = nil)
```

`DetectedObject` is a public value type:

```swift
public struct DetectedObject: Equatable {
    public let label: String       // top Vision label
    public let confidence: Float   // 0...1
    public let boundingBox: CGRect // normalized (0...1), origin bottom-left (Vision convention)
}
```

The overload is chosen by the binding's element type: pass `Binding<[String]>` for labels only, or
`Binding<[DetectedObject]>` for positions. Vision's bounding-box origin is bottom-left, so flip the
`y` axis (`1 - boundingBox.midY`) when positioning a SwiftUI overlay.

Full example (labels only):

```swift
import SwiftUI
import PrototypeKit

struct ObjectDetectorViewSample: View {
    @State var detectedObjects: [String] = []

    var body: some View {
        VStack {
            ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
                               detectedObjects: $detectedObjects)

            ScrollView {
                ForEach(Array(detectedObjects.enumerated()), id: \.offset) { index, object in
                    Text(object)
                }
            }
        }
    }
}
```

Full example (bounding boxes):

```swift
import SwiftUI
import PrototypeKit

struct ObjectDetectorBoxesSample: View {
    @State var detectedObjects: [DetectedObject] = []

    var body: some View {
        ZStack {
            ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
                               detectedObjects: $detectedObjects)

            GeometryReader { geometry in
                ForEach(Array(detectedObjects.enumerated()), id: \.offset) { _, object in
                    let box = object.boundingBox
                    Rectangle()
                        .stroke(.red, lineWidth: 2)
                        .frame(width: box.width * geometry.size.width,
                               height: box.height * geometry.size.height)
                        .position(x: box.midX * geometry.size.width,
                                  y: (1 - box.midY) * geometry.size.height)
                        .overlay(Text(object.label))
                }
            }
        }
    }
}
```

### `LiveTextRecognizerView` — live text recognition / OCR

Signature:

```swift
public init(detectedText: Binding<[String]> = .constant([]))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct TextRecognizerView: View {
    @State var detectedText: [String] = []

    var body: some View {
        VStack {
            LiveTextRecognizerView(detectedText: $detectedText)

            ScrollView {
                ForEach(Array(detectedText.enumerated()), id: \.offset) { line, text in
                    Text(text)
                }
            }
        }
    }
}
```

### `LiveBarcodeRecognizerView` — live barcode / QR scanning

Signature:

```swift
public init(detectedBarcodes: Binding<[String]> = .constant([]))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct BarcodeRecognizerView: View {
    @State var detectedBarcodes: [String] = []

    var body: some View {
        VStack {
            LiveBarcodeRecognizerView(detectedBarcodes: $detectedBarcodes)

            ScrollView {
                ForEach(Array(detectedBarcodes.enumerated()), id: \.offset) { index, barcode in
                    Text(barcode)
                }
            }
        }
    }
}
```

### `LiveAnimalRecognizerView` — live animal recognition (cats & dogs)

Uses the built-in Vision animal recognizer — no Core ML model required.

Signature:

```swift
public init(detectedAnimals: Binding<[String]> = .constant([]))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct AnimalRecognizerView: View {
    @State var detectedAnimals: [String] = []

    var body: some View {
        VStack {
            LiveAnimalRecognizerView(detectedAnimals: $detectedAnimals)

            ScrollView {
                ForEach(Array(detectedAnimals.enumerated()), id: \.offset) { index, animal in
                    Text(animal)
                }
            }
        }
    }
}
```

### `LiveFaceDetectorView` — live face detection

Uses the built-in Vision face detector — no Core ML model required. Publishes the number
of faces found in the latest frame.

Signature:

```swift
public init(faceCount: Binding<Int> = .constant(0))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct FaceDetectorView: View {
    @State var faceCount: Int = 0

    var body: some View {
        VStack {
            LiveFaceDetectorView(faceCount: $faceCount)
            Text("Faces: \(faceCount)")
        }
    }
}
```

### `LiveBodyPoseDetectorView` — live human body pose detection

Uses the built-in Vision human body pose request — no Core ML model required. Publishes the
number of bodies found in the latest frame.

Signature:

```swift
public init(bodyCount: Binding<Int> = .constant(0))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct BodyPoseDetectorView: View {
    @State var bodyCount: Int = 0

    var body: some View {
        VStack {
            LiveBodyPoseDetectorView(bodyCount: $bodyCount)
            Text("Bodies: \(bodyCount)")
        }
    }
}
```

### `LiveRectangleDetectorView` — live rectangle detection

Uses the built-in Vision rectangle detector — no Core ML model required. Detects rectangular
shapes (documents, cards, signs) and publishes the count found in the latest frame.

Signature:

```swift
public init(rectangleCount: Binding<Int> = .constant(0))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct RectangleDetectorView: View {
    @State var rectangleCount: Int = 0

    var body: some View {
        VStack {
            LiveRectangleDetectorView(rectangleCount: $rectangleCount)
            Text("Rectangles: \(rectangleCount)")
        }
    }
}
```

### `HandPoseClassifierView` — hand-pose classification (Core ML)

Detects a hand pose with Vision and classifies keypoints with your Core ML model.

Signature:

```swift
public init(modelURL: URL, latestPrediction: Binding<String> = .constant(""))
```

Full example:

```swift
import SwiftUI
import PrototypeKit

struct HandPoseSample: View {
    @State var latestPrediction: String = ""

    var body: some View {
        VStack {
            HandPoseClassifierView(modelURL: HandPoseClassifier.urlOfModelInThisBundle,
                                   latestPrediction: $latestPrediction)
            Text(latestPrediction)
        }
    }
}
```

### `.recognizeSounds` — live sound recognition (iOS 15+ only)

A `View` modifier. Uses the built-in system sound classifier by default, or a
custom Core ML model via the configuration.

Signature:

```swift
@available(iOS 15.0, *)
public func recognizeSounds(recognizedSound: Binding<String?>,
                            configuration: SoundAnalysisConfiguration = .init()) -> some View
```

Configuration:

```swift
public struct SoundAnalysisConfiguration {
    public init(inferenceWindowSize: Double = 1.5,  // seconds of audio per prediction
                overlapFactor: Double = 0.9,        // 0–1 overlap between windows
                mlModel: MLModel? = nil)            // nil = system classifier
}
```

Full example (system classifier):

```swift
import SwiftUI
import PrototypeKit

struct SoundRecognizerView: View {
    @State var recognizedSound: String?

    var body: some View {
        VStack {
            Text("Recognized Sound: \(recognizedSound ?? "None")")
        }
        .recognizeSounds(recognizedSound: $recognizedSound)
    }
}
```

Custom model + configuration:

```swift
.recognizeSounds(
    recognizedSound: $recognizedSound,
    configuration: SoundAnalysisConfiguration(
        inferenceWindowSize: 1.5,
        overlapFactor: 0.9,
        mlModel: yourCustomModel   // an MLModel instance
    )
)
```

### Natural Language — text analysis (no camera, mic, permissions, or model)

Three `View` modifiers wrap Apple's `NaturalLanguage` framework. They need no camera,
microphone, privacy keys, or Core ML model, and work on **both iOS and macOS**. Each
re-runs whenever the `text` you pass changes, updating a binding with the result.

Signatures:

```swift
public func analyzeSentiment(text: String, score: Binding<Double>) -> some View
public func identifyLanguage(text: String, language: Binding<String?>) -> some View
public func tagEntities(text: String, entities: Binding<[String]>) -> some View
```

- `analyzeSentiment` — `score` ranges from `-1` (very negative) to `1` (very positive); `0` is neutral.
- `identifyLanguage` — `language` is a BCP-47 code (e.g. `"en"`, `"fr"`), or `nil` if undetermined.
- `tagEntities` — `entities` are the recognized people, place, and organization names.

Full example (sentiment):

```swift
import SwiftUI
import PrototypeKit

struct SentimentView: View {
    @State var text: String = "I love this!"
    @State var score: Double = 0

    var body: some View {
        VStack {
            TextField("Type something", text: $text)
            Text("Sentiment: \(score, specifier: "%.2f")")
        }
        .analyzeSentiment(text: text, score: $score)
    }
}
```

## Gotchas

- **Missing privacy key = crash.** Add `NSCameraUsageDescription` (camera views)
  and `NSMicrophoneUsageDescription` (`recognizeSounds`) before running.
- **Bad model URL.** `ImageClassifierView` / `ObjectDetectorView` /
  `HandPoseClassifierView` degrade gracefully if the model fails to load — the camera
  feed still shows but no predictions/detections are produced, and the failure is logged
  (and reported to `onError` where available). Verify the model is in the target's bundle
  and the generated class name matches.
- **Simulator limits.** The camera isn't available in the iOS Simulator (limited
  preview), and inference falls back to CPU-only in the simulator and under XCTest.
- **`recognizeSounds` is iOS-only** and requires iOS 15+. It is not available on
  macOS. Gate calls with `if #available(iOS 15.0, *)` where needed.
- Prediction/detection values arrive asynchronously through the `@Binding`s; drive
  other SwiftUI views off those state variables as usual.
- **Natural Language modifiers** (`analyzeSentiment`, `identifyLanguage`, `tagEntities`)
  are the exception to most of the above: no camera/mic, no privacy keys, no Core ML
  model, and they run on macOS too. They re-analyse whenever the `text` argument changes.
