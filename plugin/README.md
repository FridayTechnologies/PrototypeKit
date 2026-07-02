# PrototypeKit — Claude Code plugin

A Claude Code plugin that teaches Claude how to build with
[PrototypeKit](https://github.com/FridayTechnologies/PrototypeKit), the SwiftUI
framework for rapid on-device ML prototyping on iOS/macOS.

It ships:

- A **knowledge skill** (`prototypekit`) that Claude auto-invokes whenever you work
  with PrototypeKit — exact initializer signatures, `@State`/`@Binding` wiring, the
  required `Info.plist` privacy keys, Core ML model setup, and the common gotchas.
- **Scaffolding slash commands** that generate correct, ready-to-run SwiftUI views.

## Install

```
/plugin marketplace add FridayTechnologies/PrototypeKit
/plugin install prototypekit@prototypekit
```

To try it locally from a clone of this repo:

```
claude --plugin-dir ./plugin
```

## Commands

| Command | What it does |
| --- | --- |
| `/prototypekit:setup` | Add the SwiftPM package and configure Info.plist privacy keys |
| `/prototypekit:camera` | Scaffold a live camera feed (`PKCameraView`) |
| `/prototypekit:image-classifier` | Scaffold live image classification (`ImageClassifierView`, Core ML) |
| `/prototypekit:object-detector` | Scaffold live object detection (`ObjectDetectorView`, Core ML) |
| `/prototypekit:text-recognizer` | Scaffold live text recognition / OCR (`LiveTextRecognizerView`) |
| `/prototypekit:barcode-scanner` | Scaffold live barcode/QR scanning (`LiveBarcodeRecognizerView`) |
| `/prototypekit:animal-recognizer` | Scaffold live animal recognition — cats & dogs (`LiveAnimalRecognizerView`) |
| `/prototypekit:face-detector` | Scaffold live face detection (`LiveFaceDetectorView`) |
| `/prototypekit:body-pose-detector` | Scaffold live body pose detection (`LiveBodyPoseDetectorView`) |
| `/prototypekit:rectangle-detector` | Scaffold live rectangle detection (`LiveRectangleDetectorView`) |
| `/prototypekit:hand-pose` | Scaffold hand-pose classification (`HandPoseClassifierView`, Core ML) |
| `/prototypekit:action-classifier` | Scaffold action classification from body movement (`ActionClassifierView`, Core ML) |
| `/prototypekit:sound-recognizer` | Scaffold sound recognition (`.recognizeSounds`, iOS 15+) |
| `/prototypekit:natural-language` | Scaffold on-device text analysis — sentiment, language ID, entities (no camera/model) |

You don't have to use the commands — the skill also activates automatically when you
ask Claude for any of these features in plain language.

## Notes

- Camera views require `NSCameraUsageDescription`; `.recognizeSounds` requires
  `NSMicrophoneUsageDescription`. Missing keys crash the app at runtime.
- Classifier views take a Core ML `.mlmodel` you add to your Xcode project.
- `.recognizeSounds` is iOS 15+ and iOS-only.
