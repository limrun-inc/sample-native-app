# Limrun Localhost Tunnel Demo

This native iOS app shows a cloud simulator reaching services on the presenter’s
Mac through Limrun. The app calls ordinary `localhost` URLs before and after the
tunnel starts. There is no rebuild, endpoint swap or simulator-side VPN.

## Setup

Export a Limrun API key and install the current CLI:

```bash
export LIM_API_KEY=lim_...
npm install --global lim@latest
lim --version # 0.29.2 or newer
```

The repo includes Limrun skills under `.agents/skills` for coding agents.

## Demo flow

Use two terminals. Keep Terminal A visible beside the simulator so the audience
can see requests arrive.

### 1. Start two services on this Mac

Terminal A:

```bash
node demo-services.mjs
```

It starts:

- `http://localhost:4100` — a local API
- `http://localhost:3000` — a local dev server

The server accepts live commands:

```text
api down
api up
dev down
dev up
status
quit
```

### 2. Build and launch the app remotely

Terminal B:

```bash
lim xcode build . --configuration Debug
IOS_ID="$(lim ios create --attach --no-open --quiet)"
echo "$IOS_ID"
```

On launch, the app checks both localhost destinations. Both cards should turn
red even though Terminal A shows both services are running.

> Pause here. The important setup is visible: the cloud iPhone is calling its
> own localhost, while the services live on the presenter’s Mac.

### 3. Start one transparent tunnel

Terminal B:

```bash
lim ios tunnel \
  --id "$IOS_ID" \
  --route localhost:4100 \
  --route localhost:3000 \
  --detach
```

Tap **Run live check**. Both cards turn green, response messages appear, and
Terminal A prints the requests. The app still displays the same localhost URLs.

### 4. Demonstrate independent failure and recovery

In Terminal A:

```text
api down
```

Tap **Run live check** again. The API card turns red while the dev-server card
stays green.

Then:

```text
api up
```

Run the check once more. The API card returns green and shows **RECOVERED**.
The tunnel was never recreated.

### 5. Show and clean up the tunnel

Terminal B:

```bash
lim ios tunnel status --id "$IOS_ID"
lim ios tunnel stop --id "$IOS_ID"
lim ios delete "$IOS_ID"
```

In Terminal A, enter `quit`.

## Talk track

- “The app is already built against localhost.”
- “The services are running here, but the cloud iPhone cannot reach them.”
- “This command declares exactly two ports. It does not expose the whole Mac.”
- “The app does not change. Limrun moves the connection.”
- “Each route fails independently, and recovery does not recreate the tunnel.”
