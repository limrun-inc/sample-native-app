# AGENTS.md

## Cursor Cloud specific instructions

### Overview

This is a minimal SwiftUI iOS sample app (`sample-native-app`) built for the Limrun cloud iOS simulator platform. There is no local Xcode or iOS simulator available — all builds and tests run on Limrun cloud instances.

### Prerequisites

- `LIM_API_KEY` must be set as an environment variable (get one from https://console.limrun.com).
- The `lim` CLI is installed by running `bash setup.sh` at the repo root. This clones the Limrun TypeScript SDK from GitHub and builds/links the CLI globally.
- Node.js and npm are required for the `lim` CLI.

### Building and running

1. **Create an iOS instance**: `lim run ios --xcode --reuse-if-exists --label name=<label> --json`
2. **Start a session**: `lim session start <INSTANCE_ID>` (enables fast ~50ms exec latency)
3. **Sync code**: `lim sync <INSTANCE_ID> . --no-watch`
4. **Build**: `lim build <INSTANCE_ID> --project sample-native-app.xcodeproj`
5. **Launch**: `lim exec launch-app <INSTANCE_ID> com.limrun.sample-native-app`
6. **Verify**: `lim exec element-tree <INSTANCE_ID> --json` (preferred) or `lim exec screenshot <INSTANCE_ID> -o <path>`

Always `sleep 2` after `launch-app` before inspecting the element tree.

### Gotchas

- The `@limrun/cli` npm package is not published to the public npm registry. You must install via `setup.sh` which clones from GitHub and runs `npm link`.
- `lim session start` is a long-running foreground process — run it in a background tmux session or with `&`.
- Always clean up instances when done: `lim delete ios <INSTANCE_ID>`. Unused instances cost money.
- The app bundle ID is `com.limrun.sample-native-app`.

### Testing

There are no automated unit/integration tests in this repo. Testing is done by building, launching the app on a Limrun cloud simulator, and verifying via element tree or screenshots. See the skill files in `.agents/skills/limrun-skill/SKILL.md` for the full testing workflow.

### Lint

No linter is configured for this project.
