---
description: Scaffold a PrototypeKit live camera feed (PKCameraView) in a SwiftUI view.
argument-hint: "[optional: target view/file name]"
---

Add a live camera feed using PrototypeKit's `PKCameraView`. Follow the exact API in
the `prototypekit` skill.

1. Generate a self-contained SwiftUI `View` embedding `PKCameraView()`. If the user
   passed a name in `$ARGUMENTS`, use it for the view; otherwise pick a sensible name
   and place it appropriately in their project.
2. Ensure `import SwiftUI` and `import PrototypeKit` are present.
3. Remind the user to add `NSCameraUsageDescription` (*Privacy - Camera Usage
   Description*) to Info.plist, and note the camera is unavailable in the iOS
   Simulator.

Reference example:

```swift
import SwiftUI
import PrototypeKit

struct CameraView: View {
    var body: some View {
        VStack {
            PKCameraView()
        }
        .padding()
    }
}
```

Prefer editing the user's actual files over just printing code when a target is clear.
