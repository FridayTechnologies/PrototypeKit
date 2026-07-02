# Security Policy

## Scope

PrototypeKit is a SwiftUI toolkit for prototyping on-device machine-learning features. All inference
runs on-device using Apple's frameworks (Vision, Core ML, Sound Analysis, Natural Language, Core
Motion); PrototypeKit does not collect, store, or transmit user data, and it ships a
`PrivacyInfo.xcprivacy` manifest declaring no tracking and no data collection.

Because PrototypeKit is intended for prototyping and idea validation, please review it before relying
on it in a production, safety-critical, or sensitive context.

## Supported versions

PrototypeKit is pre-1.0. Security fixes are made against the latest `master`; there is no long-term
support branch yet. Pin a released `0.x` version and update promptly when a fix ships.

## Reporting a vulnerability

Please **do not** open a public issue for security-sensitive reports.

Instead, use GitHub's private vulnerability reporting:

1. Go to the repository's **Security** tab → **Report a vulnerability**
   (<https://github.com/FridayTechnologies/PrototypeKit/security/advisories/new>).
2. Describe the issue, the affected version/commit, and reproduction steps.

If private reporting is unavailable, contact the maintainers privately rather than filing a public
issue.

### What to expect

- We aim to acknowledge a report within a few business days.
- We'll work with you on a fix and coordinate a disclosure timeline.
- With your permission, we're happy to credit you in the release notes.

Thank you for helping keep PrototypeKit and the apps built with it safe.
