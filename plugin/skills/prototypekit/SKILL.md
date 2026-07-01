---
name: prototypekit
description: >-
  Reference and code-generation guide for PrototypeKit, a SwiftUI framework for
  rapid on-device machine-learning prototyping on iOS/macOS. Use whenever the
  user is building with PrototypeKit or asks for a live camera feed, on-device
  image classification, live text/OCR recognition, barcode scanning, hand-pose
  classification, or sound recognition in a SwiftUI app. Provides exact
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

Any camera-based view (`PKCameraView`, `ImageClassifierView`,
`LiveTextRecognizerView`, `LiveBarcodeRecognizerView`, `HandPoseClassifierView`)
requires a camera-usage description, or the app crashes on launch of that view:

- **Camera:** key `NSCameraUsageDescription` — shown in Xcode's Info tab as
  `Privacy - Camera Usage Description`. Value: a human-readable reason.

The sound modifier requires microphone access:

- **Microphone:** key `NSMicrophoneUsageDescription` —
  `Privacy - Microphone Usage Description`.

To add: select the project ▸ your target ▸ **Info** tab ▸ right-click the
"Custom iOS Target Properties" table ▸ **Add Row** ▸ pick the key ▸ type the reason.

## Core ML models

Views that classify (`ImageClassifierView`, `HandPoseClassifierView`) take a
`modelURL: URL` pointing at a compiled Core ML model.

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

## Gotchas

- **Missing privacy key = crash.** Add `NSCameraUsageDescription` (camera views)
  and `NSMicrophoneUsageDescription` (`recognizeSounds`) before running.
- **Bad model URL.** `ImageClassifierView` / `HandPoseClassifierView` currently
  call `fatalError()` if the model fails to load. Verify the model is in the
  target's bundle and the generated class name matches.
- **Simulator limits.** The camera isn't available in the iOS Simulator (limited
  preview), and inference falls back to CPU-only in the simulator and under XCTest.
- **`recognizeSounds` is iOS-only** and requires iOS 15+. It is not available on
  macOS. Gate calls with `if #available(iOS 15.0, *)` where needed.
- Prediction/detection values arrive asynchronously through the `@Binding`s; drive
  other SwiftUI views off those state variables as usual.
