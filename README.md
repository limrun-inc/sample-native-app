# Preview pull requests against services in your network

This sample shows a pull request preview that reaches services only your network
can reach. The app lists orders from a staging API at `api.staging.internal`, a
hostname that resolves only inside your network. Each order also shows a
delivery estimate from an ETA service on `localhost:4100`, which this pull
request adds and which runs on your laptop. A
[persistent tunnel](https://docs.limrun.com/docs/networking/persistent-tunnels)
named `staging` connects every preview simulator to both services.

`demo/services.mjs` stands in for both services, and this Mac stands in for a
machine inside your network.

## Before you begin

- Install `lim` 0.43.0 or later with `npm install --global lim`.
- Get an admin API key of the organization whose key is in the repository's
  `LIM_API_KEY` secret. Only admins create tunnels.
- Install Node.js 18 or later.

## Set up the tunnel once

1. Map the staging hostname to this Mac's LAN IP:

   ```bash
   echo "$(ipconfig getifaddr en0) api.staging.internal" | sudo tee -a /etc/hosts
   ```

   Use the LAN IP, not `127.0.0.1`: the tunnel never dials a loopback address
   for a domain. When your LAN IP changes, for example on another Wi-Fi
   network, update this line. `demo/services.mjs` refuses to start until the
   hostname points at this Mac.

2. Create the tunnel:

   ```bash
   lim tunnel create staging --selector "*.staging.internal" --selector localhost:4100
   ```

   The command prints the connector command, `lim tunnel run --token <token>`.
   Save it, because the token is shown only once.

## Run the demo

1. Start the services:

   ```bash
   node demo/services.mjs
   ```

   The terminal prints every request the services receive.

2. In a second terminal, start the connector with the command you saved:

   ```bash
   lim tunnel run --token <token>
   ```

   It prints `Tunnel staging is active`, then one line for each simulator it
   attaches.

3. Open a pull request from this branch. When the **Limrun Preview** comment
   appears, select **Open Preview**.

   The simulator attaches to the tunnel, launches the app, and opens order
   #1042. The order comes from `api.staging.internal` and its delivery estimate
   from `localhost:4100`, and the first terminal prints both requests.

4. Tap the back button. The list of orders also comes from the staging API.

5. To show that the services fail independently, open an order, enter
   `eta down` in the first terminal, and tap **Refresh**. The **Delivery**
   section reports the failure while the order still loads. Enter `eta up` and
   tap **Refresh** again.

## How the workflow configures the preview

`.github/workflows/build.yaml` passes three inputs to the iOS preview action:

```yaml
tunnel: staging
env: |
  API_URL=http://api.staging.internal:4200
  ETA_URL=http://localhost:4100
open-url: limrun-demo://orders/1042
```

- `tunnel` attaches the preview simulator to the `staging` tunnel before the app
  launches, so the app's first request already reaches your network.
- `env` sets the app's launch environment. The build carries no backend URL, so
  the same build runs against another environment when you change these
  values. The preview applies them to the launch it performs: if you relaunch
  the app from the home screen, it starts without them and shows
  **No backend configured**.
- `open-url` opens a deep link after the app launches, so reviewers land on the
  screen the pull request changes.

The preview link in the pull request comment contains these values, so keep
them nonsecret.
