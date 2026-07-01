---
description: Add PrototypeKit to an Xcode/SwiftPM project and configure the required Info.plist privacy keys.
---

Help the user add **PrototypeKit** to their project and configure it correctly.
Follow the canonical setup in the `prototypekit` skill.

Do the following:

1. **Add the Swift Package.**
   - For an Xcode app: instruct them to use **File ▸ Add Package Dependencies…**
     and enter `https://github.com/FridayTechnologies/PrototypeKit`.
   - If the project has a `Package.swift`, add the dependency and target link:
     ```swift
     .package(url: "https://github.com/FridayTechnologies/PrototypeKit", branch: "master")
     ```
     and add `"PrototypeKit"` to the relevant target's `dependencies`.

2. **Configure Info.plist privacy keys** — required or the app crashes at runtime:
   - `NSCameraUsageDescription` (shown as *Privacy - Camera Usage Description*) for
     any camera-based view.
   - `NSMicrophoneUsageDescription` (*Privacy - Microphone Usage Description*) if
     they will use `.recognizeSounds`.
   Explain how to add a row via the target's **Info** tab, and only add the keys
   the features they intend to use require.

3. **Confirm the import:** `import PrototypeKit` in files that use it.

4. Ask which feature they want to build next (camera, image classifier, text/OCR,
   barcode, hand pose, or sound) and point them at the matching `/prototypekit:*`
   command.

If the user described a specific project layout or feature, tailor the steps to it
rather than dumping all options.
