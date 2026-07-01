---
description: Scaffold a PrototypeKit live barcode / QR scanner view (LiveBarcodeRecognizerView).
argument-hint: "[optional: target view/file name]"
---

Add live barcode/QR scanning using PrototypeKit's `LiveBarcodeRecognizerView`.
Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveBarcodeRecognizerView(detectedBarcodes: Binding<[String]>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var detectedBarcodes: [String] = []`,
   - embeds `LiveBarcodeRecognizerView(detectedBarcodes: $detectedBarcodes)`,
   - lists the detected payloads (e.g. in a `ScrollView` + `ForEach`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

```swift
import SwiftUI
import PrototypeKit

struct BarcodeRecognizerView: View {
    @State var detectedBarcodes: [String] = []

    var body: some View {
        VStack {
            LiveBarcodeRecognizerView(detectedBarcodes: $detectedBarcodes)

            ScrollView {
                ForEach(Array(detectedBarcodes.enumerated()), id: \.offset) { index, barcode in
                    Text(barcode)
                }
            }
        }
    }
}
```

Prefer editing the user's actual files over just printing code when a target is clear.
