---
description: Scaffold a PrototypeKit live body pose detector view (LiveBodyPoseDetectorView).
argument-hint: "[optional: target view/file name]"
---

Add live human body pose detection using PrototypeKit's `LiveBodyPoseDetectorView`.
Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveBodyPoseDetectorView(bodyCount: Binding<Int>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var bodyCount: Int = 0`,
   - embeds `LiveBodyPoseDetectorView(bodyCount: $bodyCount)`,
   - shows the count (e.g. a `Text("Bodies: \(bodyCount)")`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
