---
description: Scaffold PrototypeKit on-device text analysis (sentiment, language ID, entity recognition).
argument-hint: "[optional: target view/file name]"
---

Add on-device natural-language analysis using PrototypeKit's Natural Language view modifiers.
Follow the exact API in the `prototypekit` skill.

These modifiers wrap Apple's `NaturalLanguage` framework. They need **no camera, microphone,
Info.plist privacy keys, or Core ML model**, and work on **both iOS and macOS** — the simplest
PrototypeKit features to get running. Each re-runs whenever the `text` argument changes.

Signatures to use:

```swift
.analyzeSentiment(text: String, score: Binding<Double>)      // -1 (negative) … 1 (positive)
.identifyLanguage(text: String, language: Binding<String?>)  // BCP-47 code, e.g. "en", "fr"
.tagEntities(text: String, entities: Binding<[String]>)      // people, places, organizations
```

1. Ask which task the user wants (sentiment, language identification, or entity recognition) if it
   is not clear from `$ARGUMENTS`; sentiment is the most common default.
2. Generate a SwiftUI `View` that:
   - declares a `@State var text: String` for the input (often bound to a `TextField`),
   - declares a `@State` result variable matching the modifier's binding type,
   - applies the chosen modifier to its body, passing `text` and the `$result` binding,
   - displays the result.
   Use a name from `$ARGUMENTS` if provided.
3. Ensure `import SwiftUI` and `import PrototypeKit`.
4. No Info.plist changes are required for these features.

Reference example (sentiment):

```swift
import SwiftUI
import PrototypeKit

struct SentimentView: View {
    @State var text: String = "I love this!"
    @State var score: Double = 0

    var body: some View {
        VStack {
            TextField("Type something", text: $text)
            Text("Sentiment: \(score, specifier: "%.2f")")
        }
        .analyzeSentiment(text: text, score: $score)
    }
}
```

Prefer editing the user's actual files over just printing code when a target is clear.
