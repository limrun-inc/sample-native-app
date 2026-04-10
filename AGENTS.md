# AGENTS.md

## Cursor Cloud specific instructions

### Codebase overview

This is a minimal **sample native iOS app** (SwiftUI, Swift 5.0) for the [Limrun](https://limrun.com) platform. It consists of just two Swift source files and an Xcode project — no dependencies, no tests, no backend services.

The intended workflow (per the README) is: build with `xcodebuild` on macOS → archive as `.app.tar.gz` → push to Limrun Asset Storage → launch on a cloud iOS Simulator instance.

### Development environment on Linux (Cloud Agent)

**This is an iOS/Xcode project that cannot be fully built on Linux** — `xcodebuild` and the iOS Simulator SDK are macOS-only. However, the following development tools are available for validation work:

| Tool | Location | Purpose |
|---|---|---|
| Swift 6.1.3 | `/opt/swift/usr/bin/swift` | Syntax checking (`swiftc -parse`) and type-checking (Linux-only modules) |
| SwiftLint 0.63.2 (static) | `/usr/local/bin/swiftlint` | Linting Swift source files |
| swift-format | `/opt/swift/usr/bin/swift-format` | Format checking |

**Important:** Add `/opt/swift/usr/bin` to `PATH` before using Swift tools:
```bash
export PATH=/opt/swift/usr/bin:$PATH
```

### Available checks on Linux

- **Lint:** `swiftlint lint` — runs SwiftLint on all `.swift` files. The `type_name` violation on `sample_native_appApp` is from Xcode's auto-generated naming and is expected.
- **Syntax check:** `swiftc -parse sample-native-app/*.swift` — validates Swift syntax without compiling.
- **Format check:** `swift-format lint sample-native-app/*.swift` — indentation warnings are expected (Xcode uses 4-space indent, swift-format defaults to 2-space).
- **Type check** (`swiftc -typecheck`) will fail because `SwiftUI` module is unavailable on Linux — this is expected.

### What cannot be done on Linux

- Full compilation (`xcodebuild`) — requires macOS + Xcode 26.2+
- Running the app (iOS Simulator) — requires macOS
- Running automated tests — no test targets exist in this project
- Pushing to Limrun Asset Storage — requires the `lim` CLI and API credentials
