# Changelog

All notable changes to PrototypeKit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
once tagged releases begin.

## [Unreleased]

_Nothing yet._

## [0.1.0] - 2026-07-02

First tagged release. PrototypeKit remains a prototyping toolkit, but this release makes it
safe to embed in a real app: no code path crashes the host app on bad input, all diagnostics
go through `os.Logger`, and the public view API is unchanged from prior `master`.

### Changed
- **Crash safety.** PrototypeKit no longer crashes the host app on bad input. View
  initializers that previously called `fatalError()` when a Core ML model failed to load
  (`ImageClassifierView`, `HandPoseClassifierView`, `classifyActivity(...)`) now log the
  failure and degrade gracefully — the camera feed still shows, but no predictions are
  produced.
- Per-frame Vision requests no longer use `try!`; failures are logged and the frame is
  skipped instead of trapping.
- Live sound recognition no longer uses `assertNoFailure()`, which could trap the app when
  the audio session was interrupted or microphone access was denied. Errors are now logged
  and swallowed, leaving the last recognized value in place.
- Creating a sound request from a custom Core ML model no longer uses `try!`.
- Live sound recognition now recovers after an audio interruption or error. Results are
  published on a long-lived relay in `SystemAudioClassifier` that never completes; a failed
  session is logged and torn down without killing the stream, so restarting classification
  resumes delivery. Previously a single failure permanently stopped recognition for the app's
  lifetime (the shared subject completed and could never emit again).
- An unknown microphone-authorization status is treated as "no access" rather than calling
  `fatalError()`.
- Diagnostics now go through the unified logging system (`os.Logger`, subsystem
  `com.prototypekit.PrototypeKit`) instead of `print(...)`, so the library no longer writes
  to a consuming app's console in Release builds.
- The camera view controllers now act on the `NSCameraUsageDescription` check: when the key
  is missing, iOS shows a clear on-screen message instead of a black preview.

### Added
- **Privacy manifest.** Ships a `PrivacyInfo.xcprivacy` in the library's resource bundle
  declaring no tracking, no data collection, and no "required reason" API usage — so apps that
  embed PrototypeKit get an accurate App Store privacy report. (Camera/microphone usage strings
  remain the host app's responsibility.)

### Fixed
- The simulator placeholder message on iOS now activates its width constraint (previously it
  was created but never applied) and wraps long text.
- **Concurrency safety.** Replaced `[unowned self]` with `[weak self]` in the camera
  controllers' async permission/session blocks (an `unowned` reference would crash if the
  controller was torn down while a block was queued). All `@Published` prediction updates are
  published on the main thread, and `PKLogger` is now `Sendable`.

### Performance
- The camera capture pipeline no longer allocates a `CIContext` for every frame; each
  coordinator now reuses a single context, which is significantly cheaper and restores its
  internal caching.

### Deprecations & platform fixes
- Removed all uses of the deprecated `VNRequest.usesCPUOnly`. This also fixes a latent bug:
  the CPU-only path was gated on `#if canImport(XCTest)`, which is effectively always true, so
  the library was forcing CPU-only inference **in production**. Image and hand-pose
  classification now use the default (all available) compute units on device; the macOS
  receiver tests pin `computeUnits = .cpuOnly` explicitly to stay deterministic.
- Migrated `AVCaptureConnection.videoOrientation` (deprecated in iOS 17 / macOS 14) to
  `videoRotationAngle` via a helper that falls back to the old API on earlier systems.
- macOS now selects the system default video device (`AVCaptureDevice.default(for:)`) instead
  of requesting a `.back`-position wide-angle camera, which returns `nil` on most Macs.

### CI
- Removed a duplicate `actions/checkout` step from the Swift workflow, upgraded it to `v4`,
  pinned the simulator destination to `OS=latest`, and added `concurrency` cancellation.
- Broadened CI into separate jobs: iOS + macOS tests now collect code coverage (summarised in
  the job summary); a new job builds for a generic iOS device to validate the minimum
  deployment target and availability annotations; and two non-blocking audit jobs run SwiftLint
  and a complete-concurrency (Swift 6 readiness) build.
- Added a `.swiftlint.yml` (lenient, curated rule set) and Dependabot for GitHub Actions.
- Cleaned up the SwiftLint violations the new lane surfaced, and gave the macOS Core ML
  receiver tests a CI-appropriate 60s timeout (coverage instrumentation made the previous
  10s limit flaky on cold-start inference). The strict-concurrency lane is advisory-only and
  never fails the build.

### Meta
- Aligned the plugin marketplace catalog version with the pre-release (`0.1.0`) status.
- Added this changelog.

[Unreleased]: https://github.com/FridayTechnologies/PrototypeKit/compare/0.1.0...HEAD
[0.1.0]: https://github.com/FridayTechnologies/PrototypeKit/releases/tag/0.1.0
