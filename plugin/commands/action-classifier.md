---
description: Scaffold a PrototypeKit action classifier view (ActionClassifierView) that classifies a person's action from their body movement, backed by a Core ML model.
argument-hint: "[optional: Core ML model class name, e.g. ActionClassifier]"
---

Add action classification using PrototypeKit's `ActionClassifierView`. It detects a
person's body-pose keypoints with Vision and classifies their action from a sliding
window of frames using your Core ML model. Follow the exact API in the `prototypekit`
skill.

Signature to use:
`ActionClassifierView(modelURL:, configuration: ActionClassifierConfiguration = .init(), latestPrediction: Binding<String> = .constant(""), camera: CameraOptions? = nil, onError: ((PrototypeKitError) -> Void)? = nil)`.

An action unfolds over time, so the view collects a window of frames (two seconds by
default) before its first prediction and updates as the window advances. If the model
uses different feature names or a different window, pass an `ActionClassifierConfiguration`
(`posesFeatureName`, `labelFeatureName`, `predictionWindowSize`, `predictionInterval`).

1. Generate a SwiftUI `View` that:
   - declares `@State var latestPrediction: String = ""`,
   - embeds `ActionClassifierView(modelURL: <Model>.urlOfModelInThisBundle, latestPrediction: $latestPrediction)`,
   - displays `Text(latestPrediction)`.
   Use the model class name from `$ARGUMENTS` if provided; otherwise use a
   placeholder like `ActionClassifier` and tell the user to replace it.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to:
   - train/drag in an action-classifier `.mlmodel` (Xcode generates the class used above), and
   - add `NSCameraUsageDescription` to Info.plist.
   A bad/missing model URL degrades gracefully (the camera feed shows but no predictions
   are produced); use the optional `onError` closure to surface the failure in the UI.

Reference example:

```swift
import SwiftUI
import PrototypeKit

struct ActionClassifierSample: View {
    @State var latestPrediction: String = ""

    var body: some View {
        VStack {
            ActionClassifierView(modelURL: ActionClassifier.urlOfModelInThisBundle,
                                 latestPrediction: $latestPrediction)
            Text(latestPrediction)
        }
    }
}
```

Prefer editing the user's actual files over just printing code when a target is clear.
