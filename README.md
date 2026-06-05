# MeshMonitor Raspberry Pi Deployer

This project helps new users deploy [MeshMonitor](https://meshmonitor.org/) to a Raspberry Pi from either macOS or Windows.

Your local machine only needs Docker. Deployment runs inside a container that executes an [Ansible](https://docs.ansible.com/#get_started) playbook against your Pi.

---

## Brand-new to all of this? Start here

This is a complete, copy-paste walkthrough that takes you from a Raspberry Pi
you just unboxed to a working MeshMonitor dashboard. You do not need to
understand Docker, Ansible, or the command line — just follow the steps in
order. The deeper reference sections further down explain how everything works,
but you don't need them to get going.

### What you need

**Hardware**
- A Raspberry Pi (a Pi 4 or Pi 5 is ideal) with a power supply and an SD card.
- A Meshtastic LoRa radio that is already set up and powered on. For Wi-Fi mode
  it must be on your home Wi-Fi with a known IP address; for Bluetooth mode it
  must be paired to the Pi first (see [`docs/BLUETOOTH_GUIDE.md`](docs/BLUETOOTH_GUIDE.md)).
- Your everyday computer — a **Mac or Windows PC** — on the **same network** as
  the Pi. This is where you run the commands; the Pi does the hosting.

**Software (on your Mac/PC, not the Pi)**
- **Docker Desktop**, installed and running. Download:
  [macOS](https://docs.docker.com/desktop/setup/install/mac-install/) ·
  [Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
  Open it once and leave it running in the background.
- **Git**, so you can download this project. ([Install guide](https://git-scm.com/downloads).)

**On the Pi itself**
- Raspberry Pi OS already flashed to the SD card and booted, with **SSH enabled**
  and connected to your network. The official
  [Raspberry Pi getting-started guide](https://www.raspberrypi.com/documentation/computers/getting-started.html#install)
  walks through this. During imaging you set a **username and password** —
  write both down, you'll need them below.
- You need the Pi's **IP address** (looks like `192.168.1.50`). You can find it
  in your router's device list, or in the Raspberry Pi Imager / Pi Connect.

**Time required:** about 15–30 minutes, most of it unattended while the Pi
installs software.

### Step-by-step: blank Pi to working dashboard

Run every command below on your **Mac or PC** (not on the Pi). Each step is one
action. Copy the whole block, paste it into your terminal, press Enter.

> Mac: open the **Terminal** app. Windows: open **PowerShell**.

**1. Download this project to your computer.**

```bash
git clone https://github.com/efmesh/meshmonitor-pi-deployer.git
```

You'll see lines like `Cloning into 'meshmonitor-pi-deployer'...` followed by
download progress. When it returns to a normal prompt, it's done.

**2. Move into the project folder.**

```bash
cd meshmonitor-pi-deployer
```

Your prompt now shows you're inside the `meshmonitor-pi-deployer` folder.

**3. Make sure Docker is running.**

```bash
docker --version
```

You should see a version line such as `Docker version 27.x.x`. If you instead
get "command not found" or "Cannot connect to the Docker daemon", open Docker
Desktop and wait for it to finish starting, then try again.

**4. Start the deployer.**

On **Mac**:

```bash
chmod +x scripts/run.sh
./scripts/run.sh
```

On **Windows (PowerShell)**:

```powershell
./scripts/run.ps1
```

The script now asks you a series of questions, one at a time. Steps 5–11 below
cover each prompt in the order it appears. Just type your answer and press Enter.

**5. `Pi IP address:`** — type the Pi's IP address (e.g. `192.168.1.50`).

**6. `Pi SSH username [pi]:`** — type the username you created when you imaged
the Pi, then Enter. If you left the default and your Pi user really is `pi`, you
can just press Enter to accept the `[pi]` shown in brackets. Note: recent
Raspberry Pi OS images **no longer create a `pi` user automatically**, so this is
usually whatever name you chose during setup — not necessarily `pi`.

**7. `Pi password:`** — type your Pi login password. Nothing appears as you
type (that's normal for password fields). Press Enter.

**8. `MeshMonitor radio connection (wifi/bluetooth) [wifi]:`** — type `wifi` (or
press Enter to accept the default) if your radio is on Wi-Fi; type `bluetooth`
if you paired it over Bluetooth.

**9. Radio address.**
- If you chose **wifi**: `LoRa radio IP address:` — type your radio's IP.
- If you chose **bluetooth**: `LoRa radio MAC (AA:BB:CC:DD:EE:FF):` — type the
  radio's MAC address.

**10. `Which Electric Forest camp / area is this node at?`** — pick a number from
the list, or choose **Other** to type your own label (e.g. `GA Loop 5 by the
showers`). This is just a name used in the node's automatic messages.

**11. `MeshMonitor admin password to set:`** — choose the password you'll use to
log into the MeshMonitor dashboard. This must be **at least 8 characters** and
cannot be `changeme`. See "Choosing your dashboard password" just below for the
rules. Nothing appears as you type. Press Enter. You may then be asked for an
optional sunrise message — press Enter to accept the default.

**12. Wait.** The deployer now builds and connects to your Pi, installs Docker,
Nginx, and MeshMonitor, and configures everything. This is the long part —
several minutes, sometimes more on a slow Pi or network. You'll see a stream of
status lines. You don't need to do anything; let it run to completion.

**13. Done.** When it finishes you'll see a **deployment summary** box (see
"What success looks like" below) with the URL to open. You're finished.

### Choosing your dashboard password

The admin password you set in step 11 is the one you'll use to log into the
MeshMonitor web dashboard. The only rules are:

- **At least 8 characters.** Shorter passwords are rejected immediately, before
  anything is changed on the Pi (this is MeshMonitor's own minimum).
- **Not `changeme`** (that's the factory default the deployer replaces).
- **Any characters are allowed** — letters, numbers, spaces, emoji, and symbols
  like `$`, quotes, or backticks all work. They're handled safely, so use
  whatever makes a strong password.

> About the username prompt (step 6): that asks for the **Pi's Linux login
> name** (how the deployer logs into the Pi over SSH), *not* your MeshMonitor
> dashboard login. The dashboard username is always `admin`. If you didn't use
> the old default `pi` user when setting up your Pi, enter your actual Pi
> username at the prompt — leaving it as `pi` when your account is named
> something else will cause the connection to fail.

### What success looks like

When the run finishes, the last thing printed is a summary box like this:

```
============================================================
MeshMonitor deployed successfully.
------------------------------------------------------------
Open it in a browser:  http://<your-pi-ip>/
Log in as:             admin
Password:              the MESHMONITOR_ADMIN_PASSWORD you set
                       (the default 'changeme' is now disabled)
------------------------------------------------------------
First load note: MeshMonitor is a single-page app. ...
============================================================
```

Then:

1. Open a web browser and go to **`http://<your-pi-ip>/`** (the URL shown in the
   summary — for example `http://192.168.1.50/`).
2. Log in with username **`admin`** and the dashboard password you chose in
   step 11.
3. **The dashboard may look blank or empty for a little while on first load —
   this is expected, not broken.** MeshMonitor is starting up and waiting to
   hear traffic from the mesh. The node list and map fill in over time as your
   radio reports activity. If the page is still fully blank after a few seconds,
   do a hard refresh (`Ctrl+Shift+R` on Windows, `Cmd+Shift+R` on Mac).

That's it — your node is live on the mesh with the Electric Forest automations
already seeded.

### Troubleshooting

**The install log says `trying default admin/changeme` (or similar).**
This is **normal on a first install**, not a failure. A brand-new MeshMonitor
only knows the factory `changeme` password, so the deployer logs in with it once
to set *your* password. The log now spells this out as expected behavior. The
run only reports success after it confirms `changeme` no longer works — if your
password somehow didn't take, it stops with a loud error instead.

**The dashboard is blank / white when I open it.**
Expected on first load (see "What success looks like"). Give it a few seconds,
then hard-refresh (`Ctrl/Cmd+Shift+R`). A brand-new node also shows an empty
node list until it hears mesh traffic; that fills in on its own.

**My password was rejected.**
The admin password must be **at least 8 characters** and not `changeme`. The
script tells you which rule failed and lets you try again — just enter a longer
password. Any characters (spaces, emoji, symbols) are fine.

**`Cannot connect to the Docker daemon` or `docker: command not found`.**
Docker Desktop isn't running (or isn't installed). Open Docker Desktop, wait for
its whale icon to stop animating, then re-run the step.

**SSH / connection errors to the Pi** (timeouts, "permission denied").
Double-check the Pi's IP address, that you entered the **correct Pi username**
(step 6) and password, and that the Pi is powered on and on the same network.
The deployer is safe to re-run — fixing the input and running `./scripts/run.sh`
again picks up where it needs to.

> The walkthrough above is the fast path. The sections below are reference
> material — how the deployer works, all configuration variables, radio-mode
> details, and advanced internals — if you want to go deeper.

---

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
- Pi user has sudo privileges. The deployer prompts for the SSH username and
  defaults to `pi`, but recent Raspberry Pi OS images no longer create a `pi`
  user automatically — use the username you set up during Pi imaging.

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
- `MESHMONITOR_ADMIN_PASSWORD` (required to seed automations; at least 8
  characters, not `changeme`; any characters allowed including spaces/emoji)
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
  changes the default `changeme` password during seeding and verifies the
  default no longer works — if seeding can't set your password it fails loudly
  rather than silently leaving `changeme` in place)
- Electric Forest automations are seeded and ready (see
  [`docs/EF_AUTOMATIONS.md`](docs/EF_AUTOMATIONS.md))

### First load: a brief blank screen is normal

MeshMonitor is a single-page web app. On the very first visit you may see a
blank/white screen for a few seconds while it loads and connects to your radio —
this is more noticeable on slower Pis. If it stays blank, hard-refresh
(`Ctrl/Cmd+Shift+R`). A brand-new node also starts with an empty node/map view
until it hears traffic from the mesh; that is expected and fills in over time.

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
