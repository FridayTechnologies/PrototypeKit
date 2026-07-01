---
description: Scaffold a PrototypeKit live rectangle detector view (LiveRectangleDetectorView).
argument-hint: "[optional: target view/file name]"
---

Add live rectangle detection (documents, cards, signs) using PrototypeKit's
`LiveRectangleDetectorView`. Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveRectangleDetectorView(rectangleCount: Binding<Int>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var rectangleCount: Int = 0`,
   - embeds `LiveRectangleDetectorView(rectangleCount: $rectangleCount)`,
   - shows the count (e.g. a `Text("Rectangles: \(rectangleCount)")`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
