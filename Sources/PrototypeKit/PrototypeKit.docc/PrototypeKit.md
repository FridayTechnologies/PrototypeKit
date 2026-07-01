# ``PrototypeKit``

Prototype on-device machine learning apps with SwiftUI in just a few lines of code.

## Overview

PrototypeKit is a lightweight, zero-dependency wrapper around Apple's camera, Vision,
Core ML, and Sound Analysis frameworks. It exposes ready-made SwiftUI views and modifiers
so you can validate ideas quickly without writing AVFoundation and Vision boilerplate.

> Important: PrototypeKit is a work in progress and is **not** intended for production use.

### Getting started

1. Add the package to your project (see the README for Swift Package Manager instructions).
2. Add the required Info properties for the features you use:
   - Camera-based views require `NSCameraUsageDescription` (Privacy - Camera Usage Description).
   - ``SwiftUI/View/recognizeSounds(recognizedSound:configuration:)`` requires
     `NSMicrophoneUsageDescription` (Privacy - Microphone Usage Description).
3. Drop a view into your SwiftUI hierarchy:

```swift
import SwiftUI
import PrototypeKit

struct ContentView: View {
    @State private var latestPrediction = ""

    var body: some View {
        VStack {
            ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle,
                                latestPrediction: $latestPrediction)
            Text(latestPrediction)
        }
    }
}
```

## Topics

### Camera

- ``PKCameraView``
- ``CameraOptions``

### Vision & Core ML

- ``ImageClassifierView``
- ``HandPoseClassifierView``
- ``LiveTextRecognizerView``
- ``LiveBarcodeRecognizerView``

### Sound

- ``SoundAnalysisConfiguration``

### Motion

- ``SwiftUI/View/classifyActivity(modelURL:configuration:latestActivity:)``
- ``ActivityClassifierConfiguration``
</content>
