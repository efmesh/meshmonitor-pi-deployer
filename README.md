# MeshMonitor Raspberry Pi Deployer

This project helps new users deploy [MeshMonitor](https://meshmonitor.org/) to a Raspberry Pi from either macOS or Windows.

Your local machine only needs Docker. Deployment runs inside a container that executes an [Ansible](https://docs.ansible.com/#get_started) playbook against your Pi.

## What this deployer does

- Connects to your Raspberry Pi over SSH.
- Installs Docker Engine and Docker Compose plugin.
- Installs and configures Nginx as a reverse proxy.
- Deploys MeshMonitor using Docker Compose.

## What the user provides

- Pi IP address
- Pi password
- MeshMonitor radio connection type: `wifi` or `bluetooth`
- If `wifi`: the LoRa radio IP address
- If `bluetooth`: the paired LoRa radio MAC address (for example `AA:BB:CC:DD:EE:FF`)

The radio connection type controls how MeshMonitor on the Pi talks to the LoRa radio.

- `wifi`: MeshMonitor uses wifi transport for the radio path and you must provide `RADIO_IP`.
- `bluetooth`: MeshMonitor uses a `meshtastic-ble-bridge` sidecar for bluetooth transport, and you must provide `RADIO_MAC`.

If `wifi` is selected, the LoRa radio must already be connected to your Wi-Fi network and reachable at the provided `RADIO_IP`. Radio Wi-Fi onboarding is out of scope for this deployer.

If `bluetooth` is selected, pairing the Pi onboard Bluetooth adapter to the radio is expected to be done manually first. See [`docs/BLUETOOTH_GUIDE.md`](docs/BLUETOOTH_GUIDE.md).

This setting does not control how your computer connects to the Pi for deployment. Deployment to the Pi always uses SSH to the Pi IP you provide.

## Prerequisites

- This repository cloned to your local machine ([GitHub cloning guide](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository))
- Docker Desktop installed and running ([Windows](https://docs.docker.com/desktop/setup/install/windows-install/) or [macOS](https://docs.docker.com/desktop/setup/install/mac-install/))
- Raspberry Pi reachable via SSH from the machine running the deployer ([Pi Getting Started guide](https://www.raspberrypi.com/documentation/computers/getting-started.html#install))
- Pi user has sudo privileges (default username is `pi`)

## Verified Pi devices and OS versions

Use this table to track combinations that have been validated with this deployer.

| Raspberry Pi model | OS version | Architecture | Radio mode tested | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| Pi 2 Model B v1.1 | Trixie OS Lite | 32-bit | WiFi | Verified | Testing only, Pi 2 not recommended for actual deployment |

## Configuration

Copy `.env.example` to `.env` and customize as needed. These are minimal required variables to run the deployer:

- `TARGET_PI_IP` (required; Pi IP Ansible connects to)
- `PI_USERNAME` (default: `pi`)
- `RADIO_CONNECTION_TYPE` (`wifi` || `bluetooth`; default: `wifi`)
- `RADIO_IP` (required when `RADIO_CONNECTION_TYPE=wifi`)
- `RADIO_MAC` (required when `RADIO_CONNECTION_TYPE=bluetooth`)
- `TARGET_PI_PASSWORD` (optional convenience; scripts can reuse it)
- `EF_CAMP` (your camp / location label; prompted if unset)
- `MESHMONITOR_ADMIN_PASSWORD` (required to seed automations; not `changeme`)
- `EF_MORNING_MESSAGE` (optional sunrise message; has a camp-substituted default)
- `FORCE_SEED` (optional; `true` to re-apply seeded automations)

## Electric Forest turnkey automations

This deployer seeds a fresh MeshMonitor instance with a turnkey set of Electric
Forest automations so your node is useful on the mesh as soon as it comes up:

- **Auto-ack** — replies to test/ping messages with a hop + SNR/RSSI report that
  mentions your camp.
- **Auto-ping** — others can DM `ping #` to request a ping test.
- **Auto-responder** — canned DM replies (`hey`→hey, `ping`→pong, `test`→ack).
- **Auto-welcome** — one-time DM the first time it sees a new node.
- **Auto-time-sync** and **auto-key-management** — keep the mesh healthy.
- **Sunrise announce** — posts a "Good Morning" to forest-chat at 6:05 AM
  (America/Detroit).
- Sensible display defaults (map centered on Double JJ Ranch, miles/°F, 12h).

When you run the deploy script you're prompted for three new things:

- **Camp picker** — pick a known Electric Forest camp/area (GA Campgrounds,
  Good Life Village, Camp Higher Love, Maplewoods, Lucky Lake, The Back 40) or
  type your own (e.g. `GA Loop 5 by the showers`). This is baked into the
  seeded messages.
- **MeshMonitor admin password** — set on first deploy (must not be `changeme`).
- **Sunrise morning message** — optional; defaults to
  `🌅 Good Morning from <CAMP>! ☀️🌲`.

These map to the `EF_CAMP`, `MESHMONITOR_ADMIN_PASSWORD`, and
`EF_MORNING_MESSAGE` variables (see `.env.example`). All seeded values are
editable later in the MeshMonitor UI under **Settings → Automation**.

Seeding is idempotent: a seed-version marker on the Pi means reruns are a no-op
once seeded. Set `FORCE_SEED=true` to re-apply the seeded settings.

See [`docs/EF_AUTOMATIONS.md`](docs/EF_AUTOMATIONS.md) for the full automation
table, efmesh channel assumptions, the sunrise schedule, and airtime notes
(auto-welcome DMs every new node — dense-mesh users may want it off).

## Quick start (macOS)

```bash
chmod +x scripts/run.sh
./scripts/run.sh
```

## Quick start (Windows PowerShell)

```powershell
./scripts/run.ps1
```

## Deployment outcome

After deployment:

- Nginx listens on Pi port 80
- Nginx proxies to `127.0.0.1:<MESHMONITOR_HTTP_PORT>`, the Pi host port Docker publishes (the container itself listens on 3001)
- MeshMonitor container is configured for the selected radio mode (`wifi` or `bluetooth`) via container environment
- Wifi mode configures MeshMonitor with the provided `RADIO_IP`
- Bluetooth mode deploys `meshtastic-ble-bridge` with the provided `RADIO_MAC`
- MeshMonitor is configured to use `meshtastic-ble-bridge` (`meshtastic-ble-bridge:<MESHTASTIC_BLE_BRIDGE_PORT>`)
- Visit `http://<PI_IP>/`
- Login as `admin` with the `MESHMONITOR_ADMIN_PASSWORD` you set (the deployer
  changes the default `changeme` password during seeding)
- Electric Forest automations are seeded and ready (see
  [`docs/EF_AUTOMATIONS.md`](docs/EF_AUTOMATIONS.md))

## Idempotent reruns

The deploy script is designed to be idempotent.

You can run `./scripts/run.sh` or `./scripts/run.ps1` again against the same Pi, and the playbook will only apply changes that are needed for the current desired configuration.

Typical rerun use cases:

- Retrying after a network timeout or transient package install failure
- Switching between `wifi` and `bluetooth` radio modes
- Updating config inputs like `RADIO_IP` or `RADIO_MAC`
- Picking up newer container images when tags are updated

## Current scope and next steps

This deployer currently sets up basic MeshMonitor usage (infrastructure and runtime wiring).

Automating full MeshMonitor configuration is a future goal.

For current configuration details and walkthrough, use this video:

- https://www.loom.com/share/39db92235bb3422b9f3fdf7daa241f1c

## More docs

- Advanced internals and customization: [docs/ADVANCED_GUIDE.md](docs/ADVANCED_GUIDE.md)
