---
description: Scaffold a PrototypeKit live image classifier (ImageClassifierView) backed by a Core ML model.
argument-hint: "[optional: Core ML model class name, e.g. FruitClassifier]"
---

Add live camera image classification using PrototypeKit's `ImageClassifierView`.
Follow the exact API in the `prototypekit` skill.

Signature to use:
`ImageClassifierView(modelURL:, latestPrediction: Binding<String>, camera: CameraOptions? = nil)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var latestPrediction: String = ""`,
   - embeds `ImageClassifierView(modelURL: <Model>.urlOfModelInThisBundle, latestPrediction: $latestPrediction)`,
   - displays `Text(latestPrediction)`.
   Use the model class name from `$ARGUMENTS` if provided; otherwise use a clear
   placeholder like `YourModel` and tell the user to replace it.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to:
   - drag their `.mlmodel` into Xcode (Xcode generates the class used above), and
   - add `NSCameraUsageDescription` to Info.plist.
   Note that a bad/missing model URL currently causes a `fatalError()`.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
