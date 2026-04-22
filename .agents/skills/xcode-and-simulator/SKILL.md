---
name: limrun-skill
description: "Replaces xcodebuild with remote XCode and Simulator. Use when the user wants to build or run an iOS app, test iOS UI, see their app on a simulator, or says 'run it', 'build it', 'test it', 'show me a screenshot', or 'launch on simulator'."
user-invocable: true
effort: high
---

# Remote XCode & iOS Simulator

You are an iOS build-and-test operator. Your job is to get the user's iOS app running on a Limrun cloud simulator, verify it works, and iterate until the user is satisfied. You own the full cloud infrastructure lifecycle -- the user should never need to think about provisioning, syncing, or cleanup.

All builds and simulator operations run on Limrun. Never use local Xcode, local simulators, or local macOS build tools.

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

## Build and Reload

### Build

Instead of `xcodebuild` command, you MUST use the following to build the iOS app.

```bash
lim xcode build
```

Use `--scheme` and `--workspace` flags if the project has multiple schemes or uses a workspace file. Because sync is watching, every build uses the latest code. If the build fails, read the errors, fix the code, and rebuild.

Once the build is completed, the app is re-launched with the new version.

### Verify

After launch, use the element tree as your primary verification method -- it is faster and more reliable than screenshots:

```bash
lim ios element-tree --json
```

Use screenshots if you need to verify visual properties (colors, layout, gradients) that the element tree cannot capture:

```bash
lim ios screenshot -o /tmp/limrun-screen.png
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

After every build, test new or changed functionality with a lightweight bash test script. Focus on what changed plus a quick smoke test of core flows.

Use element tree for functional assertions (element existence, labels, state changes). Use screenshots only for visual-only properties.

```bash
lim ios launch-app com.example.MyApp
sleep 2

PASS=0
FAIL=0

# Test: main screen loads
TREE=$(lim ios element-tree --json)
if echo "$TREE" | grep -q "welcomeLabel"; then
  echo "PASS: Main screen loaded"
  PASS=$((PASS + 1))
else
  echo "FAIL: Main screen did not load"
  FAIL=$((FAIL + 1))
fi

# Test: tap and verify navigation
lim ios tap-element --ax-unique-id startButton
TREE=$(lim ios element-tree --json)
if echo "$TREE" | grep -q "detailView"; then
  echo "PASS: Navigated to detail view"
  PASS=$((PASS + 1))
else
  echo "FAIL: Did not navigate to detail view"
  FAIL=$((FAIL + 1))
fi

echo "Results: $PASS passed, $FAIL failed"
```

## Cleanup

When the user is satisfied or the conversation is ending, always clean up:

```bash
lim ios delete
```

## Gotchas

These are common failure points. Check here first when something goes wrong.

- **Instance ID is optional.** The CLI remembers the last created instance. You only need to pass an ID explicitly when controlling multiple instances.
- **No sleep needed between `tap-element` and `element-tree`.** The tap blocks until complete.
- **Use `PASS=$((PASS + 1))` not `((PASS++))`.** The latter returns exit code 1 when the variable is 0, which will abort a `set -e` script.
- **`element-tree` can be large.** Pipe through `grep` or `jq` to extract what you need rather than dumping the full tree into context.
- **Build errors are your job to fix.** If a build fails, read the error output, fix the code, and rebuild. Do not ask the user to fix build errors.
- **Bundle ID discovery.** If you don't know the bundle ID, check the Xcode project files or run `lim ios list-apps` after a successful build.
