---
description: Scaffold a PrototypeKit live text recognizer / OCR view (LiveTextRecognizerView).
argument-hint: "[optional: target view/file name]"
---

Add live text recognition (OCR) using PrototypeKit's `LiveTextRecognizerView`.
Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveTextRecognizerView(detectedText: Binding<[String]>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var detectedText: [String] = []`,
   - embeds `LiveTextRecognizerView(detectedText: $detectedText)`,
   - lists the recognized lines (e.g. in a `ScrollView` + `ForEach`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

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

Prefer editing the user's actual files over just printing code when a target is clear.
