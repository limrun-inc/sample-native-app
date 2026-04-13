# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

This is a **native iOS SwiftUI app** (`sample-native-app`) targeting iOS 26.2. It is built with Xcode (`xcodebuild`) and has no package manager dependencies (no SPM, CocoaPods, or Carthage). Build instructions are in `README.md`.

### Development loop via Limrun Xcode Sandbox

Building and testing this iOS app is done entirely through **Limrun cloud Xcode sandboxes and iOS simulators**. The `xcode-sandbox/` directory contains a Node.js syncer that:

1. Creates a Limrun iOS instance with an Xcode sandbox
2. Watches local files and auto-syncs changes to the remote sandbox
3. Exposes `http://localhost:3000/xcodebuild` to trigger builds
4. Serves an MCP endpoint at `http://localhost:3000/` for tool-based build triggering

#### Starting the dev server

```bash
cd xcode-sandbox && npm run start -- /workspace
```

This takes ~30s to provision the instance and perform initial sync + build. Once ready, it prints:
- The simulator stream URL (`https://console.limrun.com/stream/<instance-id>`)
- The local build trigger endpoint

#### Triggering builds

After editing Swift files, trigger a rebuild:

```bash
curl http://localhost:3000/xcodebuild
```

Each build reinstalls the app on the simulator. Wait ~2-3s after the syncer logs the file change before triggering the build to ensure the sync completes.

#### Interacting with the simulator

The simulator exposes an MCP endpoint at `status.mcpUrl` (use the instance token as Bearer auth). Available tools:
- `screenshot-and-element-tree`: Get current screen state and accessibility tree
- `mobile-use`: Perform tap/type/scroll/pressKey/wait actions
- `open-url`: Open URLs in Safari or via deeplinks

To query the instance details programmatically:

```js
import { Limrun } from '@limrun/api';
const lim = new Limrun({ apiKey: process.env.LIM_API_KEY });
const list = await lim.iosInstances.list({ labelSelector: 'name=ios-native-build-example' });
const inst = list.items[0];
// inst.status.mcpUrl, inst.status.token
```

#### Important caveats

- Requires `LIM_API_KEY` environment variable (set via Cursor Secrets)
- Requires `xdelta3` system package for differential sync
- The syncer uses `reuseIfExists: true`, so it reuses existing instances with the same label
- Instances may be deleted after inactivity; just restart the dev server to create a new one
- On first build trigger after a code change, ensure the sync log line (`sync finished`) appears before triggering `curl /xcodebuild`

### Linting

SwiftLint (`swiftlint lint`) is installed at `/usr/local/bin/swiftlint` (static binary). Run from repo root to lint `.swift` files. The `statement_position` rule is skipped (no SourceKit on Linux).
