---
description: Scaffold a PrototypeKit live object detector (ObjectDetectorView) backed by a Core ML model.
argument-hint: "[optional: Core ML model class name, e.g. MyObjectDetector]"
---

Add live camera object detection using PrototypeKit's `ObjectDetectorView`.
Follow the exact API in the `prototypekit` skill.

Signature to use:
`ObjectDetectorView(modelURL:, detectedObjects: Binding<[String]>, camera: CameraOptions? = nil, onError: ((PrototypeKitError) -> Void)? = nil)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var detectedObjects: [String] = []`,
   - embeds `ObjectDetectorView(modelURL: <Model>.urlOfModelInThisBundle, detectedObjects: $detectedObjects)`,
   - displays the detected object labels (e.g. a `ScrollView` + `ForEach`).
   Use the model class name from `$ARGUMENTS` if provided; otherwise use a clear
   placeholder like `MyObjectDetector` and tell the user to replace it.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to:
   - drag their `.mlmodel` (a Create ML **Object Detector**) into Xcode (Xcode generates the class used above), and
   - add `NSCameraUsageDescription` to Info.plist.
   Note that a bad/missing model URL degrades gracefully (camera feed, no detections) and is
   reported through the optional `onError` closure rather than crashing.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
