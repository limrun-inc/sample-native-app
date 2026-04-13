# Sample Native App

This is a native iOS app written in Swift but can be built and tested in any environment,
such as Linux.

During development, you MUST use xcode-and-simulator skill to build the app and
test it in the simulator using `lim` CLI.

## Cursor Cloud specific instructions

- **`LIM_API_KEY`** must be set as an environment variable (injected via Secrets). The `setup-development.sh` script will fail if it is missing.
- The update script runs `./setup-development.sh`, which installs `xdelta3` (via apt) and `@limrun/cli` (via npm global). Both are idempotent.
- This is a minimal SwiftUI "Hello, world!" app with zero third-party Swift dependencies. The bundle ID is `com.limrun.sample-native-app`.
- When syncing code via `lim sync`, you must sync from a directory that contains **both** `sample-native-app/` (source) and `sample-native-app.xcodeproj/` (project) at the same level. Syncing from `/workspace` works, or you can copy both into a temp directory. **Do not** sync only the `sample-native-app/` source folder — the build will fail without the `.xcodeproj`.
- After `lim sync`, build with: `lim build $INSTANCE_ID --project sample-native-app.xcodeproj --scheme sample-native-app`
- After a successful build, launch with: `lim exec launch-app $INSTANCE_ID com.limrun.sample-native-app`
- Refer to `.agents/skills/xcode-and-simulator/SKILL.md` for the full `lim` CLI reference and the sync/build/run workflow.
