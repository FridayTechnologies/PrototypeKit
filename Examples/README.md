# PrototypeKit Examples

Reference SwiftUI code showing how to use each PrototypeKit feature. These files live outside the
Swift package's `Sources/` directory, so they are **not** compiled as part of the library — they're
meant to be copied into your own app.

## Running the examples

1. Create a new iOS app in Xcode (**File → New → Project → App**, SwiftUI lifecycle).
2. Add PrototypeKit as a package dependency (see the root [README](../README.md#installation-)).
3. Copy [`PrototypeKitExamples.swift`](PrototypeKitExamples.swift) into your app target.
4. Set `ExampleGallery()` as your root view (or present it).
5. Add the Info keys the features you try need:
   - **Camera** views: `Privacy - Camera Usage Description` (`NSCameraUsageDescription`).
   - **Sound** recognition: `Privacy - Microphone Usage Description` (`NSMicrophoneUsageDescription`).
   - **Activity** classification reads Core Motion, which needs no usage string.

## What's covered

| Feature | Needs a model? | Info key |
| --- | --- | --- |
| Live text / barcode / face / body / rectangle / animal | No | Camera |
| Image classification, hand-pose classification | Yes (Create ML) | Camera |
| Sound recognition | Optional custom model | Microphone |
| Activity classification | Yes (Create ML) | — |
| Sentiment / language / entities | No (ships with the OS) | — |

The model-backed demos show the call site with a placeholder — drop in your own Create ML model and
point `modelURL` at `YourModel.urlOfModelInThisBundle`. Each model-backed example also shows the
`onError` handler so you can surface a load failure in the UI.

> **Note:** The live camera and microphone don't run in the iOS Simulator — try these on a device.
