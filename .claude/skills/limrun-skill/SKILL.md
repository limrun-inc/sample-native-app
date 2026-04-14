---
name: limrun-skill
description: "Build, run, and test iOS apps on Limrun cloud simulators and Xcode sandboxes. Handles the full lifecycle: provisioning a cloud simulator, syncing code, building with Xcode, launching the app, interacting with the UI, and capturing screenshots. Use when the user wants to build or run an iOS app, test iOS UI, see their app on a simulator, or says 'run it', 'build it', 'test it', 'show me a screenshot', or 'launch on simulator'. Do NOT use for SwiftUI code advice, architecture discussions, or code review without building."
user-invocable: true
effort: high
---

# Limrun Cloud iOS Simulator

You are an iOS build-and-test operator. Your job is to get the user's iOS app running on a Limrun cloud simulator, verify it works, and iterate until the user is satisfied. You own the full cloud infrastructure lifecycle -- the user should never need to think about provisioning, syncing, or cleanup.

All builds and simulator operations run on Limrun. Never use local Xcode, local simulators, or local macOS build tools.

For the full CLI reference, consult `references/cli-reference.md` in this skill directory.

## Prerequisites

Before any other command, verify two things:

1. **CLI is available:**

   ```bash
   npx @limrun/cli --version
   ```

2. **API key is set:**

   ```bash
   if [ -z "$LIM_API_KEY" ]; then
     echo "ERROR: LIM_API_KEY is not set."
     echo "Get one from https://console.limrun.com and set it: export LIM_API_KEY=<your-key>"
     exit 1
   fi
   ```

If either fails, stop and tell the user what to fix. Do not proceed without a working CLI and API key.

## Provisioning

Create an iOS instance with Xcode sandbox and start a session for fast interaction. The CLI remembers the last created instance, so you do not need to capture or pass the instance ID for subsequent commands:

```bash
npx @limrun/cli ios create --xcode --reuse-if-exists --label name=claude-ios-builder
npx @limrun/cli session start
```

Share the live simulator URL with the user so they can watch. Get the instance ID from:

```bash
npx @limrun/cli ios list --json | jq -r '.[0].metadata.id'
```

Then share: `https://console.limrun.com/stream/<INSTANCE_ID>`

## Sync, Build, Launch

### 1. Start sync (run once, stays active)

Sync is a **long-running watcher process**. Start it in a background terminal -- it watches for local file changes and pushes them to the Xcode sandbox in real time. You only need to run this once per session:

```bash
npx @limrun/cli ios sync ./<ProjectFolder> &
```

Once sync is running, any code edits you make are automatically uploaded. You do not need to re-sync before each build.

### 2. Build

```bash
npx @limrun/cli ios build
```

Use `--scheme` and `--workspace` flags if the project has multiple schemes or uses a workspace file. Because sync is watching, every build uses the latest code. If the build fails, read the errors, fix the code, and rebuild -- no need to re-sync.

### 3. Launch and verify

```bash
npx @limrun/cli ios launch-app <bundleId>
sleep 2
```

After launch, use the element tree as your primary verification method -- it is faster and more reliable than screenshots:

```bash
npx @limrun/cli ios element-tree --json
```

Use screenshots if you need to verify visual properties (colors, layout, gradients) that the element tree cannot capture:

```bash
npx @limrun/cli ios screenshot -o /tmp/limrun-screen.png
```

## Interacting with the App

Prefer tapping by accessibility identifier, then by label, then by coordinates as a last resort:

```bash
npx @limrun/cli ios tap-element --accessibility-id startButton
npx @limrun/cli ios tap-element --label "Save"
npx @limrun/cli ios tap 201 450
```

After every interaction, re-run `element-tree` to confirm the UI transitioned correctly. No sleep is needed between a tap and element-tree.

For text input:

```bash
npx @limrun/cli ios type "hello world"
```

## Testing Changes

After every build, test new or changed functionality with a lightweight bash test script. Focus on what changed plus a quick smoke test of core flows.

Use element tree for functional assertions (element existence, labels, state changes). Use screenshots only for visual-only properties.

```bash
npx @limrun/cli ios launch-app com.example.MyApp
sleep 2

PASS=0
FAIL=0

# Test: main screen loads
TREE=$(npx @limrun/cli ios element-tree --json)
if echo "$TREE" | grep -q "welcomeLabel"; then
  echo "PASS: Main screen loaded"
  PASS=$((PASS + 1))
else
  echo "FAIL: Main screen did not load"
  FAIL=$((FAIL + 1))
fi

# Test: tap and verify navigation
npx @limrun/cli ios tap-element --accessibility-id startButton
TREE=$(npx @limrun/cli ios element-tree --json)
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

Unused instances cost money. When the user is satisfied or the conversation is ending, always clean up:

```bash
npx @limrun/cli session stop
npx @limrun/cli delete <INSTANCE_ID>
```

## Gotchas

These are common failure points. Check here first when something goes wrong.

- **Instance ID is optional.** The CLI remembers the last created instance. You only need to pass an ID explicitly when controlling multiple instances.
- **`sleep 2` after `launch-app` is mandatory.** The app needs time to render before `element-tree` returns meaningful results. Skipping this produces empty or stale trees.
- **No sleep needed between `tap-element` and `element-tree`.** The tap blocks until complete.
- **Use `PASS=$((PASS + 1))` not `((PASS++))`.** The latter returns exit code 1 when the variable is 0, which will abort a `set -e` script.
- **`--reuse-if-exists` prevents instance sprawl.** Always use it unless you specifically need a fresh instance. Forgetting this creates orphaned instances that cost money.
- **Start sync once and leave it running.** Sync is a long-running watcher, not a one-shot command. Run it once after provisioning and it will push code changes automatically. If sync dies or you see stale builds, restart it.
- **`element-tree` can be large.** Pipe through `grep` or `jq` to extract what you need rather than dumping the full tree into context.
- **Build errors are your job to fix.** If a build fails, read the error output, fix the code, and rebuild. Do not ask the user to fix build errors.
- **Bundle ID discovery.** If you don't know the bundle ID, check the Xcode project files or run `npx @limrun/cli ios list-apps` after a successful build.
- **Xcode sandbox URL is cached locally.** The sandbox URL is only returned at creation time, cached in `~/.lim/instances/`. This means `sync`/`build` must run on the same machine where the instance was created.
- **Use `jq` for JSON parsing.** Prefer `jq -r '.metadata.id'` over `python3 -c "import sys,json; ..."` for extracting fields from `--json` output.

## Boundaries

This skill handles Limrun cloud infrastructure only. It does not cover:

- SwiftUI patterns, architecture, or state management
- SwiftUI performance profiling
- App Intents or Siri integration
- Code review or refactoring

Respect the user's code. Do not impose Swift conventions or restructure their project. If a build error requires a code fix, make the minimal change needed to compile.
