# sample_flutter_app

A stock `flutter create` counter app used to test whether a Flutter iOS app can
be built and run with Limrun (`lim xcode build` + cloud iOS simulator) from a
Linux machine with no local Xcode.

## Verdict

**Yes, it builds and runs — with a workaround.** A vanilla Flutter project does
not build out of the box, because the Runner target's "Run Script" build phase
calls `$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh`, and the
Limrun Xcode build sandbox has **no Flutter SDK installed and no network
access** inside build-phase scripts (`curl` is blocked), so the SDK cannot be
fetched during the build either.

The workaround in this sample: prebuild every Flutter artifact on the developer
(Linux) machine and let the remote Mac only do the native Xcode part, which is
exactly what it is good at.

## How it works

1. `tool/prepare_ios_prebuilt.sh` (run locally, works on Linux):
   - `flutter precache --ios` downloads the prebuilt `Flutter.xcframework`
     engine.
   - `flutter build bundle --debug --target-platform ios` compiles the Dart
     code to a kernel snapshot and assembles `flutter_assets`.
   - Both are staged into `ios/Flutter/prebuilt/` (gitignored, ~145 MB).
2. `ios/Flutter/limrun_backend.sh` replaces `xcode_backend.sh` in the two
   Runner build phases (see `project.pbxproj`):
   - `build`: copies the prebuilt `Flutter.framework` into
     `BUILT_PRODUCTS_DIR` and assembles a Debug `App.framework` (stub dylib
     compiled with `xcrun clang` on the remote Mac + `flutter_assets` +
     `AppFrameworkInfo.plist`), mirroring what
     `flutter assemble debug_ios_bundle_flutter_assets` produces.
   - `embed_and_thin`: rsyncs both frameworks into the app bundle, same as the
     original `xcode_backend.sh embed`.
3. Build remotely (the `--include` flags force-sync paths that Flutter's
   default `.gitignore` would otherwise exclude from the code sync):

   ```bash
   ./tool/prepare_ios_prebuilt.sh
   lim xcode build . --include "^ios/Flutter/" --include "^ios/Runner/GeneratedPluginRegistrant"
   lim ios create --attach   # once; later builds auto-install
   ```

After a Dart change, re-run `flutter build bundle --debug --target-platform
ios`, re-copy `build/flutter_assets` into `ios/Flutter/prebuilt/flutter_assets`
(or just re-run the prepare script), and `lim xcode build .` again.

## Findings / limitations

- The Limrun build sandbox runs as user `limac` on macOS with Xcode available,
  but `PATH` only has Xcode tooling: no `flutter`, no CocoaPods `pod`, and
  outbound network from build scripts is blocked (`/usr/bin/curl: Operation
  not permitted`). Installing the Flutter SDK server-side during the build is
  therefore not possible; prebuilt artifacts must be synced from the client.
- `xcrun clang`, `rsync`, `plutil`, and `codesign` all work in build phases,
  which is everything the Flutter embed steps need.
- Debug (JIT/kernel) builds work with a stub `App.framework`. Release-mode
  builds need `gen_snapshot` for AOT compilation, which only ships as a macOS
  host binary — that would have to run on a Mac, so this sample covers Debug
  simulator builds only.
- Projects with Flutter **plugins** additionally need CocoaPods (or SwiftPM)
  on the build host; that is untested here since the sandbox has no `pod`.
  Plugin-free apps like this one work.
- Syncing needs `--include "^ios/Flutter/"` and
  `--include "^ios/Runner/GeneratedPluginRegistrant"` because Flutter's stock
  `.gitignore` excludes `Generated.xcconfig`, `ephemeral/`, and
  `GeneratedPluginRegistrant.*`, and the lim sync honors `.gitignore`.
- `ios/Flutter/Generated.xcconfig` references the local `FLUTTER_ROOT` path;
  that is harmless remotely since `limrun_backend.sh` never uses it.
