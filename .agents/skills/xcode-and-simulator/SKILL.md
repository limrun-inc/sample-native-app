---
name: limrun-skill
description: "Replaces xcodebuild with remote XCode and Simulators. Use when the user wants to build or run an iOS app, test iOS UI, see their app on a simulator, or says 'run it', 'build it', 'test it', 'show me a screenshot', or 'launch on simulator'."
user-invocable: true
effort: high
---

# Remote XCode & iOS Simulator

You are an iOS build-and-test operator. Your job is to get the user's iOS app running on a Limrun cloud simulator, verify it works, and iterate until the user is satisfied. 

All builds and simulator operations run on Limrun and that's why you can build iOS
apps from any environments; linux, windows, macos, VM, container etc. Never try to
use local Xcode, local simulators, or local macOS build tools.

If `lim` CLI is not installed, you can install it with the following:
```bash
npm install --global @limrun/cli
```

Before starting to build with remote XCode or use iOS simulator, run this ONCE:
```bash
# The label should be something to identify this session; could be app name + branch, or some other session identifier you use.
lim ios create --xcode --reuse-if-exists --label name=sample-native-app-ios-cloud
lim session start
```

Once the instance is created, tell the user about signed stream URL so that they
can watch while you are building.

## Build and Reload

### Build

Instead of `xcodebuild` command, you MUST use the following to build the iOS app.

```bash
lim xcode build .
```

Use `--scheme` and `--workspace` flags if the project has multiple schemes or uses a workspace file. This makes sure the files are synced with the remote xcode and triggers
a build where the build logs are streamed through stdout and stderr.

Once the build is completed, the app is re-launched with the new version. You don't
need to call launch-app command separately.

### Verify

After launch, use the element tree as your primary verification method -- it is faster and more reliable than screenshots:

```bash
lim ios element-tree --json
```

Use screenshots if you need to verify visual properties (colors, layout, gradients) that the element tree cannot capture:

```bash
lim ios screenshot -o /tmp/limrun-screen.png
```

If you would like to record, you should use the recording functionality of the simulator.

Start recording (non-blocking):
```bash
lim ios record start
```

Stop and save recording:
```bash
lim ios record stop -o /tmp/recording.mp4
```

## Interacting with the App

Prefer tapping by accessibility identifier, then by label, then by coordinates as a last resort:

```bash
lim ios tap-element --ax-unique-id startButton
lim ios tap-element --ax-label "Save"
lim ios tap 201 450
```

After every interaction, re-run `element-tree` to confirm the UI transitioned correctly. No sleep is needed between a tap and element-tree.

For text input:

```bash
lim ios type "hello world"
```

## Testing Changes

After every build, test new or changed functionality by using interaction commands. Focus on what changed plus a quick smoke test of core flows.

Use element tree for functional assertions (element existence, labels, state changes). Use screenshots only for visual-only properties.
Use video recording for most accurate interaction tests such as animations, gameplay,
real experience etc.

Generally, start with getting an element tree:
```bash
lim ios element-tree
```

Then if a single action will be taken, just call it. For example:
```bash
lim ios tap-element --ax-label Continue
```

If you will take multiple actions, you can create a chain of actions to be executed
with precise timing.

Some examples:
```bash
lim ios perform --action type=tap,x=100,y=200 --action "type=typeText,text=Hello World"

lim ios perform --action type=wait,durationMs=1000 --action type=pressKey,key=enter
```

You can write to a file and execute that too:
```bash
lim ios perform --file ./actions.yaml
```

Use `lim ios perform --help` for more details on how to use it.

## Finalize

When you are done with the changes and present to the user, you should provide a
preview link to the user so they can test it.

If you will open a PR, make sure to do this and add the preview link to PR.

First build and make remote xcode upload the build:
```
ASSET_NAME="<bundle id/pr number/ or any session identifier>.zip"
lim xcode build . --upload ${ASSET_NAME}
```

And construct this link for preview:
```
# Change ${ASSET_NAME} with asset name given above
https://console.limrun.com/preview?asset=${ASSET_NAME}&platform=ios
```

Always provide this in your last message.

## Cleanup

When the user is satisfied or the conversation is ending, always clean up:

```bash
lim ios delete
```

## Gotchas

These are common failure points. Check here first when something goes wrong.

- **Instance ID is optional.** The CLI remembers the last created instance. You only need to pass an ID explicitly when controlling multiple instances.
- **No sleep needed between `tap-element` and `element-tree`.** The tap blocks until complete.
- **`element-tree` can be large.** Pipe through `grep` or `jq` to extract what you need rather than dumping the full tree into context.
- **Build errors are your job to fix.** If a build fails, read the error output, fix the code, and rebuild. Do not ask the user to fix build errors.
- **Bundle ID discovery.** If you don't know the bundle ID, check the Xcode project files or run `lim ios list-apps` after a successful build.
