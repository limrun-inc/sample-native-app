# Sample Native App

This is a native iOS app written in Swift but can be built and tested in any environment,
such as Linux.

During development, you MUST use xcode-and-simulator skill to build the app and
test it in the simulator using `lim` CLI.

- The bundle ID is `com.limrun.sample-native`.


```bash
npm install --global lim
```

## Cursor Cloud specific instructions

- Install `lim` CLI: `npm install --global lim` (the old `@limrun/cli` package is deprecated).
- Use nvm-managed node for global installs: `export PATH="$HOME/.nvm/versions/node/v22.22.2/bin:$PATH"` before running npm commands (the system node at `/exec-daemon/node` has no write access to its global modules directory).
- Always use `lim` CLI to replace xcodebuild and iOS simulator.
- Refer to `.agents/skills/limrun-xcode-and-ios-simulator/SKILL.md` for the full `lim` CLI reference and the sync/build/run workflow.
- Build: `lim xcode build . --scheme sample-native-app --project sample-native-app.xcodeproj`
- Run on simulator: `lim ios create --attach` (attaches to the last Xcode target and auto-installs/launches the built app).
- Requires `LIM_API_KEY` environment variable for authentication.
