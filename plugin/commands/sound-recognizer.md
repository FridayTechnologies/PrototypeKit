---
description: Scaffold PrototypeKit live sound recognition via the .recognizeSounds modifier (iOS 15+).
argument-hint: "[optional: target view/file name]"
---

Add live sound recognition using PrototypeKit's `.recognizeSounds` view modifier.
Follow the exact API in the `prototypekit` skill.

Important: this feature is **iOS-only and requires iOS 15+**. It is not available on
macOS. Gate with `if #available(iOS 15.0, *)` where the deployment target needs it.

Signature to use:
`.recognizeSounds(recognizedSound: Binding<String?>, configuration: SoundAnalysisConfiguration = .init())`.

1. Generate a SwiftUI `View` that:
   - declares `@State var recognizedSound: String?`,
   - applies `.recognizeSounds(recognizedSound: $recognizedSound)` to its body,
   - displays the current value.
   Use a name from `$ARGUMENTS` if provided.
2. If the user wants a **custom Core ML sound model** or tuned windows, use
   `SoundAnalysisConfiguration(inferenceWindowSize:overlapFactor:mlModel:)`.
   Otherwise the default uses the built-in system sound classifier.
3. Ensure `import SwiftUI` and `import PrototypeKit`.
4. Remind the user to add `NSMicrophoneUsageDescription` to Info.plist.

Reference example (system classifier):

```swift
import SwiftUI
import PrototypeKit

struct SoundRecognizerView: View {
    @State var recognizedSound: String?

    var body: some View {
        VStack {
            Text("Recognized Sound: \(recognizedSound ?? "None")")
        }
        .recognizeSounds(recognizedSound: $recognizedSound)
    }
}
```

Custom model + configuration:

```swift
.recognizeSounds(
    recognizedSound: $recognizedSound,
    configuration: SoundAnalysisConfiguration(
        inferenceWindowSize: 1.5,
        overlapFactor: 0.9,
        mlModel: yourCustomModel
    )
)
```

Prefer editing the user's actual files over just printing code when a target is clear.
