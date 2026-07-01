---
description: Scaffold a PrototypeKit live face detector view (LiveFaceDetectorView).
argument-hint: "[optional: target view/file name]"
---

Add live face detection using PrototypeKit's `LiveFaceDetectorView`.
Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveFaceDetectorView(faceCount: Binding<Int>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var faceCount: Int = 0`,
   - embeds `LiveFaceDetectorView(faceCount: $faceCount)`,
   - shows the count (e.g. a `Text("Faces: \(faceCount)")`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
