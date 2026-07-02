# ``PrototypeKit``

Prototype on-device machine learning apps with SwiftUI in just a few lines of code.

## Overview

PrototypeKit is a lightweight, zero-dependency wrapper around Apple's camera, Vision,
Core ML, Sound Analysis, Natural Language, and Core Motion frameworks. It exposes ready-made
SwiftUI views and modifiers so you can validate ideas quickly without writing AVFoundation and
Vision boilerplate.

All inference runs on-device, and PrototypeKit ships a privacy manifest declaring no tracking and no
data collection. It is designed to fail gracefully — a missing model, denied permission, or
interrupted audio session degrades cleanly and is reported through the log and an optional
``PrototypeKitError`` handler, rather than crashing your app.

> Important: PrototypeKit is a work in progress aimed at prototyping and idea validation. It does not
> yet publish stable, versioned APIs — pin a `0.x` release and expect changes before 1.0.

### Getting started

1. Add the package to your project (see the README for Swift Package Manager instructions).
2. Add the required Info properties for the features you use:
   - Camera-based views require `NSCameraUsageDescription` (Privacy - Camera Usage Description).
   - ``SwiftUI/View/recognizeSounds(recognizedSound:configuration:onError:)`` requires
     `NSMicrophoneUsageDescription` (Privacy - Microphone Usage Description).
3. Drop a view into your SwiftUI hierarchy:

```swift
import SwiftUI
import PrototypeKit

struct ContentView: View {
    @State private var latestPrediction = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle,
                                latestPrediction: $latestPrediction) { error in
                errorMessage = error.localizedDescription
            }
            Text(errorMessage ?? latestPrediction)
        }
    }
}
```

See the [`Examples/`](https://github.com/FridayTechnologies/PrototypeKit/tree/master/Examples)
directory for a runnable gallery covering every feature.

## Topics

### Camera

- ``PKCameraView``
- ``CameraOptions``

### Vision & Core ML

- ``ImageClassifierView``
- ``ObjectDetectorView``
- ``HandPoseClassifierView``
- ``LiveTextRecognizerView``
- ``LiveBarcodeRecognizerView``
- ``LiveAnimalRecognizerView``
- ``LiveFaceDetectorView``
- ``LiveBodyPoseDetectorView``
- ``LiveRectangleDetectorView``

### Sound

- ``SwiftUI/View/recognizeSounds(recognizedSound:configuration:onError:)``
- ``SoundAnalysisConfiguration``

### Motion

- ``SwiftUI/View/classifyActivity(modelURL:configuration:latestActivity:onError:)``
- ``ActivityClassifierConfiguration``

### Natural Language

- ``SwiftUI/View/analyzeSentiment(text:score:)``
- ``SwiftUI/View/identifyLanguage(text:language:)``
- ``SwiftUI/View/tagEntities(text:entities:)``

### Error handling

- ``PrototypeKitError``
