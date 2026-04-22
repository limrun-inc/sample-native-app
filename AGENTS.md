# Sample Native App

This is a native iOS app written in Swift but can be built and tested in any environment,
such as Linux.

During development, you MUST use xcode-and-simulator skill to build the app and
test it in the simulator using `lim` CLI.

- The bundle ID is `com.limrun.sample-native-app`.


```bash
npm install --global @limrun/cli
```

## Cloud specific instructions

- Install `lim` CLI: `npm install --global @limrun/cli`
- Always use `lim` CLI to replace xcodebuild and iOS simulator.
- Refer to `.agents/skills/xcode-and-simulator/SKILL.md` for the full `lim` CLI reference and the sync/build/run workflow.
