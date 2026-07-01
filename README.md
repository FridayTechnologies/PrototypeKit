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
3. For **Dependency Rule**, select **Branch** and enter `master` (PrototypeKit does not
   publish versioned releases yet — see the note below).
4. Click **Add Package**, then add the **PrototypeKit** library to your app target.

### Add via `Package.swift`

If you maintain your own Swift package, add PrototypeKit to your `dependencies`:

```swift
dependencies: [
    .package(url: "https://github.com/FridayTechnologies/PrototypeKit", branch: "master")
]
```

…then add it to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["PrototypeKit"]
)
```

> **Note:** PrototypeKit is a work in progress and does not yet tag versioned releases,
> so the examples above track the `master` branch. Once tagged releases are available,
> prefer pinning a version (e.g. `from: "1.0.0"`) for reproducible builds.

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
3. You can use `latestPrediction` as you would any other state variable.

Utilise `ActivityClassifierView`

```swift
ActivityClassifierView(modelURL: ActivityClassifier.urlOfModelInThisBundle,
                       latestPrediction: $latestPrediction)
```

If your model's input/output feature names or sample rate differ from the Create ML defaults,
supply an `ActivityClassifierConfiguration`:

```swift
ActivityClassifierView(
    modelURL: ActivityClassifier.urlOfModelInThisBundle,
    configuration: ActivityClassifierConfiguration(
        sensorUpdateInterval: 1.0 / 50.0,  // Sensor sample rate in seconds (50 Hz)
        predictionWindowSize: 50           // Samples per prediction
    ),
    latestPrediction: $latestPrediction
)
```

> **Note:** Activity classification relies on `CoreMotion` and is available on iOS only. The view
> renders no visible content of its own — place it in your hierarchy to drive classification and
> read `latestPrediction`.

<details>
<summary>Full Example</summary>
<br>

```swift
import SwiftUI
import PrototypeKit

struct ActivityClassifierViewSample: View {

    @State var latestPrediction: String = ""

    var body: some View {
        VStack {
            ActivityClassifierView(modelURL: ActivityClassifier.urlOfModelInThisBundle,
                                   latestPrediction: $latestPrediction)
            Text(latestPrediction)
        }
    }
}
```
</details>

## FAQs

<details>
<summary>Is this production ready?</summary>
<br>
no.
</details>
