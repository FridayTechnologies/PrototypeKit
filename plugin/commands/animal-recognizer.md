---
description: Scaffold a PrototypeKit live animal recognizer view (LiveAnimalRecognizerView).
argument-hint: "[optional: target view/file name]"
---

Add live animal recognition (cats & dogs) using PrototypeKit's `LiveAnimalRecognizerView`.
Follow the exact API in the `prototypekit` skill.

Signature to use: `LiveAnimalRecognizerView(detectedAnimals: Binding<[String]>)`.

1. Generate a SwiftUI `View` that:
   - declares `@State var detectedAnimals: [String] = []`,
   - embeds `LiveAnimalRecognizerView(detectedAnimals: $detectedAnimals)`,
   - lists the recognized animals (e.g. in a `ScrollView` + `ForEach`).
   Use a name from `$ARGUMENTS` if provided.
2. Ensure `import SwiftUI` and `import PrototypeKit`.
3. Remind the user to add `NSCameraUsageDescription` to Info.plist.

Reference example:

```swift
import SwiftUI
import PrototypeKit

struct AnimalRecognizerView: View {
    @State var detectedAnimals: [String] = []

    var body: some View {
        VStack {
            LiveAnimalRecognizerView(detectedAnimals: $detectedAnimals)

            ScrollView {
                ForEach(Array(detectedAnimals.enumerated()), id: \.offset) { index, animal in
                    Text(animal)
                }
            }
        }
    }
}
```

Prefer editing the user's actual files over just printing code when a target is clear.
