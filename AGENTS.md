# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

This is a **native iOS SwiftUI app** (`sample-native-app`) targeting iOS 26.2. It is built with Xcode (`xcodebuild`) and has no package manager dependencies (no SPM, CocoaPods, or Carthage). Build and run instructions are in `README.md`.

### Key constraint: macOS-only build

This project **cannot be built or run on the Linux Cloud Agent VM**. It requires macOS with Xcode 26.2+ installed. The `xcodebuild` command, iOS SDK, and iOS Simulator are all macOS-only.

### What works on Linux

- **Linting**: SwiftLint (`swiftlint lint`) is installed at `/usr/local/bin/swiftlint` (static binary, no Swift toolchain needed). Run from the repo root to lint all `.swift` files.
  - Note: the `statement_position` rule is skipped because SourceKit is not available on Linux. All other rules work.
- **Code editing**: Swift source files can be edited normally.

### What does NOT work on Linux

- `xcodebuild` (build/compile)
- iOS Simulator (run/test)
- Xcode previews
- Any tests that depend on the iOS SDK

### Services

| Service | Required? | Notes |
|---------|-----------|-------|
| Xcode + `xcodebuild` | Required (macOS only) | Builds the `.xcodeproj` |
| iOS Simulator | Required (macOS only) | Runs the built `.app` |
| Limrun Asset Storage (`lim push`) | Optional | Pushes built artifact to Limrun cloud |
