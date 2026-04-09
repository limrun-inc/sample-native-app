---
name: limrun-skill
description: "Building iOS apps in remote XCode sandbox and using them in the remote iOS Simulator. You must use this skill every time you need to build an iOS app and want to test it in a live simulator."
user-invocable: true
effort: high
---

# Limrun iOS Cloud Build & Simulator

## Overview

Provision and operate **Limrun cloud iOS simulators** so the user can build, run, and interact with their iOS app without local Xcode or a local simulator. Use this skill for building, launching, UI interaction, screenshots and more.

**IMPORTANT: All iOS builds and simulator operations MUST run on Limrun.** Do NOT attempt to use local Xcode, local simulators, or any local macOS build tools. Never suggest installing Xcode locally or running `xcodebuild` on the user's machine.

## Architecture

The CLI (`limrun-cli.ts`) is a thin client that sends commands to the already-running daemon over a Unix socket. If the daemon is not started, the first CLI command starts it.

## CLI Commands

```bash
SKILL="${CLAUDE_SKILL_DIR}"
```

### Direct invocation (one-off commands)

| Command | What it does |
| ------- | ------------ |

| `npx tsx $SKILL/limrun-cli.ts build` | Build with xcodebuild and install in the simulator (streams output) |
| `npx tsx $SKILL/limrun-cli.ts launch <bundleId>` | Launch (or relaunch) app on the simulator |
| `npx tsx $SKILL/limrun-cli.ts screenshot [path]` | Save screenshot to path (default: `/tmp/limrun-screen.jpg`), prints path |
| `npx tsx $SKILL/limrun-cli.ts tap <x> <y>` | Tap at coordinates |
| `npx tsx $SKILL/limrun-cli.ts tap-element <axId>` | Tap element by `accessibilityIdentifier` |
| `npx tsx $SKILL/limrun-cli.ts tap-label <label>` | Tap element by label text |
| `npx tsx $SKILL/limrun-cli.ts element-tree` | Print full accessibility element tree as JSON |
| `npx tsx $SKILL/limrun-cli.ts status` | Show instance ID and simulator URL |
| `npx tsx $SKILL/limrun-cli.ts destroy` | Delete the instance |

## Workflow: Build, Run, Debug

### Build

```bash
npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts build
```

If build fails: read errors, fix code, re-sync, rebuild. Do NOT give up after one failure. Iterate until it compiles.

### Run

The app will be launched after a successful build automatically.

1. **Inspect the element tree** to verify state and find elements:

   ```bash
   npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts element-tree
   ```

   Use the element tree as your **primary** verification method -- it's faster and more reliable than screenshots. Check for element existence, labels, and hierarchy.

2. **Interact with the app**:

   ```bash
   # Preferred: tap by accessibilityIdentifier
   npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts tap-element startButton

   # Tap by visible label text
   npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts tap-label "Save"

   # Last resort: tap at exact coordinates
   npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts tap 201 450
   ```

   After tapping, re-run `element-tree` to confirm the UI transitioned correctly.

3. **Use screenshots only as a fallback** when element tree is insufficient (colors, gradients, animations, layout positioning):

   ```bash
   npx tsx ${CLAUDE_SKILL_DIR}/limrun-cli.ts screenshot
   # prints: /tmp/limrun-screen.jpg
   ```

   Then call `Read` on `/tmp/limrun-screen.jpg` to view it.

4. If something is wrong: fix code, build, re-launch, re-verify.

### Functional Testing

After every build, **always test new/changed functionality** with a lightweight bash test script. Keep tests fast and focused -- only cover what changed plus a quick smoke test of core flows. Don't re-test unchanged features exhaustively.

**Testing strategy:**

- **Element tree** for functional assertions (element existence, labels, state changes, sizes, positions). This is fast and reliable.
- **Screenshots** only for visual-only properties (colors, gradients, layout aesthetics, animations) that the element tree can't capture.
- **Direct CLI calls** (not REPL) for the test script -- simpler and the output is captured cleanly in bash variables.

**Key rules:**

- Use `$CLI tap-element <id>` then `$CLI element-tree` as the core tap->assert loop. No sleep needed between these.
- Use `PASS=$((PASS + 1))` not `((PASS++))` -- the latter returns exit code 1 when the variable is 0.

## Important Reminders

- **Prefer element-tree over screenshots** for verification.
- **If a build fails 3+ times on the same error**, explain the error and ask the user how they'd like to proceed.
