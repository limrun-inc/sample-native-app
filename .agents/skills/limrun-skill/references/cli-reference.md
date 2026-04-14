# Limrun CLI Reference

All commands use `npx @limrun/cli` (no global install needed). All commands accept `--api-key` (or env `LIM_API_KEY`). Use `--json` for structured output.

Discover commands with `--help`: `npx @limrun/cli ios --help`, `npx @limrun/cli android --help`, etc.

**Instance ID is optional** on interaction commands. When omitted, the CLI uses the last created instance of the matching type. You only need to pass an ID explicitly when controlling multiple instances simultaneously.

```bash
npx @limrun/cli ios create                  # Creates ios_abc123, remembers it
npx @limrun/cli ios screenshot -o test.png  # Uses ios_abc123 automatically
npx @limrun/cli ios tap 100 200             # Still uses ios_abc123
npx @limrun/cli session start               # Starts session for ios_abc123
```

**Top-level shortcuts** auto-detect platform from instance ID prefix: `npx @limrun/cli screenshot <id>`, `npx @limrun/cli tap 100 200 <id>`, `npx @limrun/cli delete <id>`.

## Instance Lifecycle

### Create

```bash
# iOS simulator with Xcode sandbox (most common for build+test)
npx @limrun/cli ios create --xcode --reuse-if-exists --label name=claude-ios-builder

# iOS with specific device model
npx @limrun/cli ios create --model ipad --rm

# Android emulator
npx @limrun/cli android create

# Standalone Xcode sandbox (build only, no simulator)
npx @limrun/cli xcode create --rm
```

**iOS create flags:**

| Flag | Description |
| ---- | ----------- |
| `--xcode` | Attach Xcode build sandbox (required for sync/build) |
| `--model <iphone\|ipad\|watch>` | Simulator device model |
| `--reuse-if-exists` | Reuse existing instance with matching labels/region |
| `--rm` | Auto-delete on exit (Ctrl+C) |
| `--display-name <value>` | Human-readable name |
| `--region <value>` | Region (e.g. `us-west`) |
| `--hard-timeout <duration>` | Max lifetime (e.g. `1h`, `30m`) |
| `--inactivity-timeout <duration>` | Idle timeout (default: `3m`) |
| `--label <key=value>` | Labels (repeatable, used for filtering and reuse) |
| `--install <file>` | Local file to install on creation (repeatable) |
| `--install-asset <name>` | Asset name to install on creation (repeatable) |

**Android-specific flags:** `--[no-]connect` (ADB tunnel), `--[no-]stream` (scrcpy), `--adb-path <path>`

### List & Inspect

```bash
npx @limrun/cli ios list                          # Ready iOS instances
npx @limrun/cli ios list <ID>                     # Details of specific instance
npx @limrun/cli ios list --all                    # All states
npx @limrun/cli ios list --state creating         # Filter by state
npx @limrun/cli ios list --label-selector env=ci  # Filter by labels
npx @limrun/cli android list                      # Android instances
npx @limrun/cli xcode list                        # Xcode instances
npx @limrun/cli asset list                        # Assets
```

### Delete

```bash
npx @limrun/cli delete <ID>           # Auto-detect type from ID prefix and delete
npx @limrun/cli ios delete <ID>       # Delete iOS instance
npx @limrun/cli android delete <ID>   # Delete Android instance
npx @limrun/cli xcode delete <ID>     # Delete Xcode instance
npx @limrun/cli asset delete <ID>     # Delete asset
```

## Code Sync & Build

Requires `--xcode` on instance creation. Works with both iOS instances (with Xcode sandbox) and standalone Xcode instances. Instance ID is optional (uses last created).

**Sync is a long-running watcher.** By default it stays active, watches for local file changes, and pushes them to the Xcode sandbox in real time. Start it once and leave it running -- you do not need to re-sync before each build.

```bash
npx @limrun/cli ios sync ./MyProject                # Start sync watcher (stays running, pushes changes in real time)
npx @limrun/cli ios sync ./MyProject --no-watch     # One-shot sync, then exit
npx @limrun/cli ios sync ./MyProject --no-install   # Sync without installing dependencies
npx @limrun/cli ios build                            # Build with xcodebuild (uses latest synced code)
npx @limrun/cli ios build --scheme <name>            # Build specific scheme
npx @limrun/cli ios build --workspace <file>         # Specify workspace file
npx @limrun/cli ios build --scheme <name> --upload <artifact-name>  # Build and upload artifact
```

Sync auto-ignores build artifacts, `Pods/`, `Carthage/Build/`, `.swiftpm/`, `xcuserdata/`, `.dSYM/`.

The Xcode sandbox URL is only returned at creation time, cached locally in `~/.lim/instances/`. Sync/build must run on the same machine where the instance was created.

## Session Management

Sessions keep a persistent WebSocket for fast interaction (~50ms vs ~2s per command). Essential for interactive workflows and agent loops. Instance ID is optional (uses last created).

```bash
npx @limrun/cli session start              # Start session for last created instance
npx @limrun/cli session start <ID>         # Start session for specific instance
npx @limrun/cli session stop               # Stop session (auto-detect if only one)
npx @limrun/cli session stop --all         # Stop all active sessions
npx @limrun/cli session status --json      # Show all active sessions
```

Each session spawns an independent daemon per instance. Multiple sessions can run in parallel.

## Device Interaction

Commands are platform-specific (`npx @limrun/cli ios ...` or `npx @limrun/cli android ...`). Instance ID is optional on all interaction commands -- when omitted, the last created instance of that platform type is used.

### Screenshots & Recording

```bash
npx @limrun/cli ios screenshot -o screenshot.png     # Save to file
npx @limrun/cli ios screenshot                        # Output base64 to stdout
npx @limrun/cli ios record start                      # Start video recording
npx @limrun/cli ios record start --quality 8          # Custom quality (5-10)
npx @limrun/cli ios record stop -o recording.mp4      # Stop and save
```

### Tapping

```bash
npx @limrun/cli ios tap 100 200                              # Tap coordinates
npx @limrun/cli ios tap-element --accessibility-id btn_ok     # By accessibilityIdentifier
npx @limrun/cli ios tap-element --label "Submit"              # By label text
npx @limrun/cli android tap-element --resource-id com.example:id/button  # Android resource ID
npx @limrun/cli android tap-element --text "Sign In"          # Android text content
```

### Text Input & Keys

```bash
npx @limrun/cli ios type "Hello World"                   # Type into focused input
npx @limrun/cli ios type "search query" --press-enter    # Type then press Enter
npx @limrun/cli ios press-key enter                       # Press key
npx @limrun/cli ios press-key a --modifier shift          # With modifier (repeatable)
```

### Navigation & Scrolling

```bash
npx @limrun/cli ios scroll down                    # Scroll (default 300px)
npx @limrun/cli ios scroll down --amount 500       # Custom scroll amount
npx @limrun/cli ios open-url https://example.com   # Open URL on device
npx @limrun/cli ios open-url myapp://settings      # Deep links
```

### UI Inspection

```bash
npx @limrun/cli ios element-tree            # Full accessibility tree
npx @limrun/cli ios element-tree | jq '.'   # Pretty-print with jq
npx @limrun/cli ios element-tree --json     # JSON output
```

### App Management (iOS only)

```bash
npx @limrun/cli ios launch-app com.example.myapp                          # Launch app
npx @limrun/cli ios launch-app com.example.myapp --mode RelaunchIfRunning # Force relaunch
npx @limrun/cli ios terminate-app com.example.myapp                       # Terminate app
npx @limrun/cli ios list-apps                                              # List installed apps
npx @limrun/cli ios install-app ./MyApp.ipa                               # Install from file
npx @limrun/cli ios install-app https://example.com/app.ipa               # Install from URL
```

### Logs (iOS only)

```bash
npx @limrun/cli ios log com.example.myapp --lines 50   # Tail last N lines
npx @limrun/cli ios log com.example.myapp -f            # Stream continuously (Ctrl+C to stop)
```

## Assets

```bash
npx @limrun/cli asset push ./my-app.ipa                # Upload file as asset
npx @limrun/cli asset push ./my-app.ipa -n custom-name # Upload with custom name
npx @limrun/cli asset pull <id-or-name>                # Download asset
npx @limrun/cli asset pull <id-or-name> -o ./downloads # Download to specific directory
npx @limrun/cli asset list                              # List all assets
npx @limrun/cli asset list --name my-app               # Filter by name
```

## Authentication

```bash
npx @limrun/cli login      # Browser-based auth, stores in ~/.lim/config.yaml
npx @limrun/cli logout     # Remove stored API key
```

Configuration is read from (in order of precedence): CLI flags > environment variables (`LIM_API_KEY`, `LIM_API_ENDPOINT`, `LIM_CONSOLE_ENDPOINT`) > `~/.lim/config.yaml`.

## Multi-Instance

When controlling multiple instances, pass the ID explicitly since the CLI default only tracks one:

```bash
ID1=$(npx @limrun/cli ios create --model iphone --json | jq -r '.metadata.id')
ID2=$(npx @limrun/cli ios create --model ipad --json | jq -r '.metadata.id')

npx @limrun/cli session start $ID1
npx @limrun/cli session start $ID2

# Must pass ID explicitly when multiple instances exist
npx @limrun/cli ios screenshot $ID1 -o phone.png
npx @limrun/cli ios screenshot $ID2 -o tablet.png

# Clean up
npx @limrun/cli session stop --all
npx @limrun/cli delete $ID1
npx @limrun/cli delete $ID2
```
