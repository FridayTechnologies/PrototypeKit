---
description: Scaffold a PrototypeKit hand-pose classifier view (HandPoseClassifierView) backed by a Core ML model.
argument-hint: "[optional: Core ML model class name, e.g. HandPoseClassifier]"
---

Add hand-pose classification using PrototypeKit's `HandPoseClassifierView`. It
detects a hand with Vision and classifies the keypoints with your Core ML model.
Follow the exact API in the `prototypekit` skill.

Signature to use:
`HandPoseClassifierView(modelURL:, latestPrediction: Binding<String>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var latestPrediction: String = ""`,
   - embeds `HandPoseClassifierView(modelURL: <Model>.urlOfModelInThisBundle, latestPrediction: $latestPrediction)`,
   - displays `Text(latestPrediction)`.
   Use the model class name from `$ARGUMENTS` if provided; otherwise use a
   placeholder like `HandPoseClassifier` and tell the user to replace it.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to:
   - train/drag in a hand-pose `.mlmodel` (Xcode generates the class used above), and
   - add `NSCameraUsageDescription` to Info.plist.
   Note that a bad/missing model URL currently causes a `fatalError()`.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
