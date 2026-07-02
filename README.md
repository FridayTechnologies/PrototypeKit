# PrototypeKit

[![Swift](https://github.com/FridayTechnologies/PrototypeKit/actions/workflows/swift.yml/badge.svg)](https://github.com/FridayTechnologies/PrototypeKit/actions/workflows/swift.yml)

(Ironically, a prototype itself...) 😅

**Status**: Work In Progress

## Goals 🥅
- Make it easier to prototype basic Machine Learning apps with SwiftUI
- Provide an easy interface for commonly built views to assist with prototyping and idea validation
- Effectively a wrapper around the more complex APIs, providing a simpler interface (perhaps not all the same functionality, but enough to get you started and inspired!)

## Requirements 📋

- iOS 14.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15+
- Sound recognition (`recognizeSounds`) requires iOS 15.0+ and is unavailable on macOS

## Installation 📦

PrototypeKit is distributed as a [Swift Package](https://www.swift.org/package-manager/).

### Add via Xcode

1. In Xcode, choose **File → Add Package Dependencies…**
2. Paste the package URL into the search field:
   ```
   https://github.com/FridayTechnologies/PrototypeKit
   ```
3. For **Dependency Rule**, select **Up to Next Major Version** starting from `0.1.0` for
   reproducible builds. (To live on the latest unreleased changes instead, select **Branch**
   and enter `master`.)
4. Click **Add Package**, then add the **PrototypeKit** library to your app target.

### Add via `Package.swift`

If you maintain your own Swift package, add PrototypeKit to your `dependencies`:

```swift
dependencies: [
    .package(url: "https://github.com/FridayTechnologies/PrototypeKit", from: "0.1.0")
]
```

…then add it to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["PrototypeKit"]
)
```

> **Note:** PrototypeKit follows [Semantic Versioning](https://semver.org). It is still
> pre-1.0, so minor version bumps (`0.x`) may include breaking changes; pin with
> `.upToNextMinor(from: "0.1.0")` if you need stricter guarantees. See the
> [CHANGELOG](CHANGELOG.md) for what's in each release.

## Documentation & examples 📚

- **API reference** — DocC documentation is published to GitHub Pages:
  <https://fridaytechnologies.github.io/PrototypeKit/documentation/prototypekit>
- **Sample code** — the [`Examples/`](Examples) directory contains a runnable SwiftUI gallery
  covering every feature; copy [`PrototypeKitExamples.swift`](Examples/PrototypeKitExamples.swift)
  into an app to try them.

# Examples

Here are a few basic examples you can use today.

## Camera Tasks

### Start Here

1. Ensure you have created your Xcode project
2. Ensure you have added the PrototypeKit package to your project (see [Installation](#installation-) above)
3. Select your project file within the project navigator.
<img width="443" alt="Screenshot 2024-02-02 at 3 42 28 pm" src="https://github.com/FridayTechnologies/PrototypeKit/assets/10896308/815aba65-a0c7-4b82-83ee-2af66e04e550">

4. Ensure that your target is selected
<img width="295" alt="Screenshot 2024-02-02 at 3 43 22 pm" src="https://github.com/FridayTechnologies/PrototypeKit/assets/10896308/131d5c0b-6d57-40b3-a88b-29e9631a0e03">

5. Select the info tab.
6. Right-click within the "Custom iOS Target Properties" table, and select "Add Row"
<img width="741" alt="Screenshot 2024-02-02 at 3 44 40 pm" src="https://github.com/FridayTechnologies/PrototypeKit/assets/10896308/cbf05317-4b26-4f55-aab4-cea09a01e7e7">

7. Use `Privacy - Camera Usage Description` for the key. Type the reason your app will use the camera as the value.
<img width="834" alt="Screenshot 2024-02-02 at 3 46 30 pm" src="https://github.com/FridayTechnologies/PrototypeKit/assets/10896308/3b88dcf0-dda3-44df-9f65-8aed00618326">


### Live Camera View

Utilise `PKCameraView`

```swift
PKCameraView()
```

<details>
<summary>Full Example</summary>
<br>
    
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
</details>


### Live Image Classification

1. **Required Step:** Drag in your Create ML / Core ML model into Xcode.
2. Change `FruitClassifier` below to the name of your Model.
3. You can use latestPrediction as you would any other state variable (i.e refer to other views such as Slider)

Utilise `ImageClassifierView`

```swift
ImageClassifierView(modelURL: FruitClassifier.urlOfModelInThisBundle,
                                latestPrediction: $latestPrediction)
```
<details>
<summary>Full Example</summary>
<br>
    
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
</details>


### Live Object Detection

Detect and locate objects in the live camera feed using a Create ML / Core ML **Object Detector** model.

1. **Required Step:** Drag in your Create ML / Core ML object detector model into Xcode.
2. Change `MyObjectDetector` below to the name of your Model.
3. `detectedObjects` holds the labels of the objects found in the latest frame; use it as you would any other state variable.

Utilise `ObjectDetectorView`

```swift
ObjectDetectorView(modelURL: MyObjectDetector.urlOfModelInThisBundle,
                   detectedObjects: $detectedObjects)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>


### Live Hand Pose Classification

Classify hand poses in real-time using a Create ML / Core ML hand action classifier.

1. **Required Step:** Drag in your Create ML / Core ML hand pose model into Xcode.
2. Change `HandPoseClassifier` below to the name of your Model.
3. You can use `latestPrediction` as you would any other state variable.

Utilise `HandPoseClassifierView`

```swift
HandPoseClassifierView(modelURL: HandPoseClassifier.urlOfModelInThisBundle,
                       latestPrediction: $latestPrediction)
```

<details>
<summary>Full Example</summary>
<br>

```swift
import SwiftUI
import PrototypeKit

struct HandPoseClassifierViewSample: View {

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
</details>


### Live Text Recognition

Utilise `LiveTextRecognizerView`

```swift
LiveTextRecognizerView(detectedText: $detectedText)
```

<details>
<summary>Full Example</summary>
<br>
    
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
</details>

### Live Barcode Recognition

Utilise `LiveBarcodeRecognizerView`

```swift
LiveBarcodeRecognizerView(detectedBarcodes: $detectedBarcodes)
```

<details>
<summary>Full Example</summary>
<br>
    
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
</details>

### Live Animal Recognition

Recognize cats and dogs in real-time using the built-in Vision animal recognizer (no Core ML model required).

Utilise `LiveAnimalRecognizerView`

```swift
LiveAnimalRecognizerView(detectedAnimals: $detectedAnimals)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>

### Live Face Detection

Detect faces in real-time using the built-in Vision face detector (no Core ML model required).

Utilise `LiveFaceDetectorView`

```swift
LiveFaceDetectorView(faceCount: $faceCount)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>

### Live Body Pose Detection

Detect human body poses in real-time using the built-in Vision human body pose request (no Core ML model required).

Utilise `LiveBodyPoseDetectorView`

```swift
LiveBodyPoseDetectorView(bodyCount: $bodyCount)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>

### Live Rectangle Detection

Detect rectangular shapes (documents, cards, signs) in real-time using the built-in Vision rectangle detector (no Core ML model required).

Utilise `LiveRectangleDetectorView`

```swift
LiveRectangleDetectorView(rectangleCount: $rectangleCount)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>

### Live Sound Recognition

> **Required Step:** Sound recognition uses the microphone, so you must add the
> `Privacy - Microphone Usage Description` (`NSMicrophoneUsageDescription`) key to your
> target's Info properties — follow the same steps as the camera setup above, using the
> microphone key instead. Without it, classification fails silently.

Utilise `recognizeSounds` modifier to detect sounds in real-time. This feature supports both the system sound classifier and custom Core ML models.

```swift
.recognizeSounds(recognizedSound: $recognizedSound)
```

For custom configuration, you can use the `SoundAnalysisConfiguration`:

```swift
.recognizeSounds(
    recognizedSound: $recognizedSound,
    configuration: SoundAnalysisConfiguration(
        inferenceWindowSize: 1.5,  // Window size in seconds
        overlapFactor: 0.9,        // Overlap between consecutive windows
        mlModel: yourCustomModel   // Optional custom Core ML model
    )
)
```

<details>
<summary>Full Example</summary>
<br>
    
```swift
import SwiftUI
import PrototypeKit

struct SoundRecognizerView: View {
    @State var recognizedSound: String?
    
    var body: some View {
        VStack {
            Text("Recognized Sound: \(recognizedSound ?? "None")")
        }
        // Attach the modifier to a view to start listening; updates `recognizedSound` live.
        .recognizeSounds(recognizedSound: $recognizedSound)
    }
}
```
</details>

## Motion Tasks

### Live Activity Classification

Classify the device's physical activity (for example walking, running, or standing still) in
real-time from the accelerometer and gyroscope, using a Create ML / Core ML **Activity Classifier**.

1. **Required Step:** Drag in your Create ML / Core ML activity classifier model into Xcode.
2. Change `ActivityClassifier` below to the name of your Model.
3. You can use `latestActivity` as you would any other state variable.

Utilise the `classifyActivity` modifier to detect activity in real-time.

```swift
.classifyActivity(modelURL: ActivityClassifier.urlOfModelInThisBundle,
                  latestActivity: $latestActivity)
```

If your model's input/output feature names or sample rate differ from the Create ML defaults,
supply an `ActivityClassifierConfiguration`:

```swift
.classifyActivity(
    modelURL: ActivityClassifier.urlOfModelInThisBundle,
    configuration: ActivityClassifierConfiguration(
        sensorUpdateInterval: 1.0 / 50.0,  // Sensor sample rate in seconds (50 Hz)
        predictionWindowSize: 50           // Samples per prediction
    ),
    latestActivity: $latestActivity
)
```

> **Note:** Activity classification relies on `CoreMotion` and is available on iOS only. The modifier
> produces no visible content of its own — attach it to a view to drive classification and read
> `latestActivity`.

<details>
<summary>Full Example</summary>
<br>

```swift
import SwiftUI
import PrototypeKit

struct ActivityClassifierViewSample: View {

    @State var latestActivity: String?

    var body: some View {
        VStack {
            Text("Activity: \(latestActivity ?? "Detecting…")")
        }
        // Attach the modifier to a view to start classifying; updates `latestActivity` live.
        .classifyActivity(modelURL: ActivityClassifier.urlOfModelInThisBundle,
                          latestActivity: $latestActivity)
    }
}
```
</details>

## Text Tasks

Analyse text on-device with Apple's Natural Language framework. Unlike the camera and sound features,
these need **no camera, microphone, permissions, or Core ML model** — everything ships with the OS, and
they work on both iOS and macOS. That makes them the gentlest way to get started with on-device ML.

Each is a `View` modifier that re-runs whenever the `text` you pass in changes, updating a binding with
the result.

### Sentiment Analysis

Score how positive or negative a piece of text is, from `-1` (very negative) to `1` (very positive).

```swift
.analyzeSentiment(text: text, score: $score)
```

<details>
<summary>Full Example</summary>
<br>

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
</details>

### Language Identification

Detect the dominant language of a piece of text as a BCP-47 code (for example `en`, `fr`).

```swift
.identifyLanguage(text: text, language: $language)
```

<details>
<summary>Full Example</summary>
<br>

```swift
import SwiftUI
import PrototypeKit

struct LanguageView: View {

    @State var text: String = "Bonjour tout le monde"
    @State var language: String?

    var body: some View {
        VStack {
            TextField("Type something", text: $text)
            Text("Language: \(language ?? "Detecting…")")
        }
        .identifyLanguage(text: text, language: $language)
    }
}
```
</details>

### Named Entity Recognition

Extract the people, places, and organizations mentioned in a piece of text.

```swift
.tagEntities(text: text, entities: $entities)
```

<details>
<summary>Full Example</summary>
<br>

```swift
import SwiftUI
import PrototypeKit

struct EntitiesView: View {

    @State var text: String = "Tim Cook announced the news in London."
    @State var entities: [String] = []

    var body: some View {
        VStack {
            TextField("Type something", text: $text)

            ScrollView {
                ForEach(Array(entities.enumerated()), id: \.offset) { index, entity in
                    Text(entity)
                }
            }
        }
        .tagEntities(text: text, entities: $entities)
    }
}
```
</details>

## Diagnostics & error handling 🩺

PrototypeKit is designed to fail gracefully — it will **not** crash your app on bad input:

- If a Core ML model can't be loaded (wrong URL, incompatible model), the affected view still
  shows the camera feed but produces no predictions. The failure is logged rather than fatal.
- Per-frame Vision and sound-classification errors are logged and skipped.
- If your app is missing the `NSCameraUsageDescription` key, the camera view shows an on-screen
  message explaining what to add instead of a black preview.

Diagnostics use Apple's unified logging system (`os.Logger`) under the subsystem
`com.prototypekit.PrototypeKit`, so nothing is printed to your console in Release builds. To watch
PrototypeKit's logs while developing:

```sh
log stream --predicate 'subsystem == "com.prototypekit.PrototypeKit"'
```

PrototypeKit only logs developer-facing diagnostics — never the contents of camera frames,
audio, or recognized text.

## FAQs

<details>
<summary>Is this production ready?</summary>
<br>
Not yet — PrototypeKit is intended for prototyping and idea validation, and it does not yet publish
versioned releases. That said, it no longer crashes the host app on bad input (missing/invalid
models, denied permissions, audio interruptions): those paths now degrade gracefully and log
through <code>os.Logger</code>. See the <a href="CHANGELOG.md">CHANGELOG</a> for details.
</details>
