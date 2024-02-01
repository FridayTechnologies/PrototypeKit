# PrototypeKit

[![Swift](https://github.com/FridayTechnologies/PrototypeKit/actions/workflows/swift.yml/badge.svg)](https://github.com/FridayTechnologies/PrototypeKit/actions/workflows/swift.yml)

(Ironically, a prototype itself...) 😅

**Status**: Work In Progress

## Goals 🥅
- Make it easy to prototype basic ML apps with SwiftUI
- Great for beginners to learn the basics of Swift/SwiftUI while still being able to build technically impressive apps!
- Provide an easy interface for commonly built views to assist with prototyping and idea validation
- Effectively a wrapper around the more complex APIs, providing a simpler interface (perhaps not all the same functionality, but enough to get you started and inspired!)

## Examples

Here are a few basic examples you can use today.

### Real-Time Camera View

_⚠️ You need to first add the 'Privacy - Camera Usage Description' to your Info.plist. Future versions of this framework should give you runtime warnings._

Utilise `PKCameraView`

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

### Image Classification

_⚠️ You need to first add the 'Privacy - Camera Usage Description' to your Info.plist. Future versions of this framework should give you runtime warnings._

1. **Required Step:** Drag in your Create ML / Core ML model into Xcode.
2. Change `FruitClassifier` below to the name of your Model.
3. You can use latestPrediction as you would any other state variable (i.e refer to other views such as Slider)

Utilise `PKCameraView`

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

## FAQs

<details>
<summary>Is this production ready?</summary>
<br>
no.
</details>
