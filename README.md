# Limrun Tunnel Demo

This native iOS app shows a cloud simulator reaching the presenter's Mac through
Limrun three ways: a `localhost` port, a hostname that only resolves inside the
presenter's network (`api.demo.internal`), and `ifconfig.me`, whose answer shows
the egress IP moving to that Mac. There is no rebuild, endpoint swap or
simulator-side VPN.

## Setup

Export a Limrun API key and install a CLI with domain selector support:

```bash
export LIM_API_KEY=lim_...
npm install --global lim@latest
lim --version # 0.32.0 or newer
```

Make the internal-only hostname resolvable on this Mac (and nowhere else). Map
it to the Mac's LAN IP, not 127.0.0.1:

```bash
echo "$(ipconfig getifaddr en0) api.demo.internal" | sudo tee -a /etc/hosts
```

The repo includes Limrun skills under `.agents/skills` for coding agents.

## Demo flow

Use two terminals. Keep Terminal A visible beside the simulator so the audience
can see requests arrive.

### 1. Start the local services on this Mac

Terminal A:

```bash
node demo-services.mjs
```

It starts `http://localhost:4100` (a local API) and `http://api.demo.internal:4200`
(the internal-only API). The server accepts live commands:

```text
api down
api up
corp down
corp up
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

On launch, the app checks all three destinations. The **Local API** and
**Internal-only API** cards turn red: the cloud iPhone has no route to the Mac's
localhost, and `api.demo.internal` does not exist on public DNS at all. The
**Public egress IP** card turns green and shows the datacenter IP of the cloud
iPhone.

> Pause here. The important setup is visible: the cloud iPhone is calling its
> own localhost and an internal-only hostname, while both live on the
> presenter's Mac, and its traffic leaves from the datacenter.

### 3. Start one transparent tunnel

Terminal B:

```bash
lim ios tunnel \
  --id "$IOS_ID" \
  --selector localhost:4100 \
  --selector api.demo.internal \
  --selector ifconfig.me \
  --detach
```

Tap **Run live check**. The Local API and Internal-only API cards turn green
and Terminal A prints both requests; `api.demo.internal` resolved on the cloud
iPhone even though no public DNS knows it. The Public egress IP card now shows
this Mac's IP: `ifconfig.me` traffic leaves from the presenter's machine. The
app still displays the same URLs.

### 4. Demonstrate independent failure and recovery

In Terminal A:

```text
api down
```

Tap **Run live check** again. The Local API card turns red while the other two
stay green.

Then:

```text
api up
```

Run the check once more. The Local API card returns green and shows
**RECOVERED**. The tunnel was never recreated.

### 5. Show and clean up the tunnel

Terminal B:

```bash
lim ios tunnel status --id "$IOS_ID"
lim ios tunnel stop --id "$IOS_ID"
lim ios delete "$IOS_ID"
```

In Terminal A, enter `quit`.

## Talk track

- "The app is already built against localhost, an internal-only hostname, and
  ifconfig.me."
- "The services run here. The cloud iPhone cannot reach localhost, cannot even
  resolve api.demo.internal, and its internet egress is the datacenter."
- "This command declares exactly one port and two domains. It does not expose
  the whole Mac or reroute all traffic."
- "The app does not change. Limrun moves the connections, including DNS for
  the declared names."
- "The egress IP is now this Mac's. Each destination fails independently, and
  recovery does not recreate the tunnel."
