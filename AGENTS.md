# Sample Native App

This is a native iOS app written in Swift but can be built and tested in any environment,
such as Linux.

During development, you MUST use xcode-and-simulator skill to build the app and
test it in the simulator using `lim` CLI.

- The bundle ID is `com.limrun.sample-native`.


```bash
npm install --global lim
```

## Cloud specific instructions

- Install `lim` CLI: `npm install --global lim`
- Always use `lim` CLI to replace xcodebuild and iOS simulator.
- Refer to `.agents/skills/xcode-and-simulator/SKILL.md` for the full `lim` CLI reference and the sync/build/run workflow.
