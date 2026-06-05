# MeshMonitor Raspberry Pi Deployer

This project helps new users deploy [MeshMonitor](https://meshmonitor.org/) to a Raspberry Pi from either macOS or Windows.

Your local machine only needs Docker. Deployment runs inside a container that executes an [Ansible](https://docs.ansible.com/#get_started) playbook against your Pi.

> **New to the mesh side of this?** This project is just the dashboard piece. For
> the bigger picture — which Meshtastic node hardware and antennas to buy,
> recommended radio settings, stationary camp relay nodes, and how to connect at
> Electric Forest — see the EF Meshtastic guide at **[efmesh.com](https://efmesh.com)**.

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

## Deploying off-grid at camp (no router, battery + solar)

Most people run these Pis **off-grid** — at a campsite, on a LiFePO4 power
station (an EcoFlow River or similar) with solar panels, and **no internet
router anywhere nearby**. The walkthrough above assumes you're on home Wi-Fi.
This section covers what's different when there's no router at camp.

The good news: **MeshMonitor doesn't need the internet to work.** It talks to
your Meshtastic radio *locally* (over your local network in Wi-Fi mode, or
directly over Bluetooth), and the dashboard is served by the Pi itself. The only
thing a router normally gives you is a way for your phone and the Pi to find each
other on the same network — and there are easy ways to do that with no router at
all (covered below). What you lose off-grid is only the things that genuinely
need the internet (see "What works offline vs. what doesn't").

### Set up at home first, deploy at camp (strongly recommended)

Do **not** make camp the first place you try to get this working. Trying to
debug Wi-Fi, SSH, Docker, and a fresh node all at once — in the dirt, on
battery, with no internet to look things up — is miserable. Instead:

**At home, on your Wi-Fi (where you have internet and a screen):**

1. Run the entire "Brand-new to all of this? Start here" walkthrough above,
   start to finish, against the Pi on your home Wi-Fi.
2. **Verify the dashboard actually works** — open `http://<your-pi-ip>/`, log in,
   and confirm you see the MeshMonitor UI and (once your radio has heard some
   traffic) nodes showing up. This is your proof that the Pi, Docker,
   MeshMonitor, and the radio connection are all good.
3. **Pre-add your camp network** to the Pi now, while you still have internet to
   fix any mistakes (see "Phone hotspot" or "Pi as its own access point" below).
   This is the single most important off-grid prep step — the Pi can't join a
   network at camp that it was never told about.
4. Power off cleanly: `sudo shutdown -h now` (run on the Pi, or over SSH), wait
   for the activity light to stop, then unplug.

**At camp:**

- Power the Pi from your battery/solar station (see "Power" below).
- Power on your Meshtastic radio.
- The Pi boots and **automatically joins whichever known network it can find** —
  your phone hotspot, or its own access point — because you set that up at home.
- Open the dashboard from your phone (see "Finding the Pi at camp").

If the radio's **IP address changes** between home and camp (common in Wi-Fi
mode if it gets a new address from a different network), re-run the deployer once
with the new `RADIO_IP` — it's safe to re-run (see "Idempotent reruns"). This is
a good reason to favor **Bluetooth mode** for a truly portable node: the radio is
addressed by its fixed MAC, so nothing to update when you move. See
[`docs/BLUETOOTH_GUIDE.md`](docs/BLUETOOTH_GUIDE.md).

### At-camp networking: getting your phone and the Pi on the same network

Pick **one** of the two approaches below. Run all `nmcli` commands **on the Pi**
(over SSH from home, or with a keyboard/monitor plugged into the Pi). Recent
Raspberry Pi OS (Bookworm and newer) uses **NetworkManager**, so these are the
correct, current commands — ignore older guides that edit
`/etc/dhcpcd.conf` or `wpa_supplicant.conf`.

#### Option A — Phone hotspot (you want the Pi online via your phone)

Best when you have cell signal and want the Pi (and you) to reach the internet
through your phone. You pre-teach the Pi your hotspot's name and password at
home, as a *second* known network, so it auto-joins at camp.

**At home, add your hotspot as a known network** (replace the SSID and password
with your phone's hotspot name and password):

```bash
sudo nmcli connection add type wifi con-name camp-hotspot \
  ifname wlan0 ssid "Will's iPhone" \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "your-hotspot-password"

# Make the Pi prefer your home Wi-Fi when it's around, and fall back to the
# hotspot at camp (higher number = higher priority).
sudo nmcli connection modify "preconfigured" connection.autoconnect-priority 20
sudo nmcli connection modify camp-hotspot connection.autoconnect-priority 10
```

> `preconfigured` is the connection name Raspberry Pi Imager creates for your
> home Wi-Fi. List your saved connections with `nmcli connection show` if you're
> not sure what yours is called, and use that name instead.

Now the Pi will join home Wi-Fi at home and your hotspot at camp, with no
changes needed on-site.

**iPhone hotspot gotchas (these trip people up):**

- Turn **on** *Settings → Personal Hotspot → **Maximize Compatibility***. Without
  it, the iPhone runs the hotspot on 5GHz only, and the Pi's built-in Wi-Fi joins
  far more reliably on **2.4GHz**. (Maximize Compatibility forces 2.4GHz.)
- The hotspot must be **awake and broadcasting when the Pi boots.** iPhones put
  the hotspot to sleep when nothing is connected. Open *Settings → Personal
  Hotspot* and **leave that screen open** while the Pi powers on, or connect
  another device first to wake it, so the Pi sees the network and joins.
- The SSID and password must **exactly** match what you typed at home, including
  the apostrophe/curly quotes iPhones use in names like `Will's iPhone`. If in
  doubt, rename your hotspot to something plain (`Settings → General → About →
  Name`) and re-add it with the simple name.

#### Option B — Pi as its own access point (zero internet, zero router)

Best when there's **no cell signal at all**. The Pi broadcasts its **own**
Wi-Fi network; your phone connects directly to the Pi and opens the dashboard.
No router, no hotspot, no internet required — and MeshMonitor still works fully,
because it only ever needed to talk to your radio locally.

**At home, turn the Pi into an access point** (choose your own network name and
a password of at least 8 characters):

```bash
sudo nmcli connection add type wifi ifname wlan0 con-name camp-ap \
  autoconnect yes ssid "MeshMonitor-Camp"
sudo nmcli connection modify camp-ap \
  802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "pick-a-password"
sudo nmcli connection up camp-ap
```

`ipv4.method shared` makes NetworkManager hand out IP addresses to whatever
connects, and the Pi reaches itself at the fixed address **`10.42.0.1`**.

At camp:

1. On your phone, join the Wi-Fi network **`MeshMonitor-Camp`** with the password
   you set.
2. Open a browser and go to **`http://10.42.0.1/`** — that's your dashboard.

> **Important trade-off:** the Pi's single built-in Wi-Fi radio can't be both an
> access point *and* a client at the same time. While `camp-ap` is the active
> connection, the Pi is **not** on any other Wi-Fi — so in **Wi-Fi radio mode**
> your Meshtastic node would need to be on the Pi's AP network too, which is
> awkward. **For Option B, use Bluetooth radio mode** (the node connects to the
> Pi over Bluetooth, totally independent of Wi-Fi) — that's the clean off-grid
> setup. See [`docs/BLUETOOTH_GUIDE.md`](docs/BLUETOOTH_GUIDE.md).
>
> To switch the Pi back to joining your home Wi-Fi later:
> `sudo nmcli connection down camp-ap` (and `up camp-ap` to go back to AP mode).

### Finding the Pi at camp (no router admin page to check)

With no router, you can't look the Pi up in a router device list. Use one of
these instead:

- **Option B (Pi access point):** the address is always **`http://10.42.0.1/`**.
  Nothing to look up.
- **mDNS / `.local` name:** from a phone or laptop on the same network, just use
  the Pi's hostname — `http://<pi-hostname>.local/` (for example
  `http://meshmonitor.local/` if you named the Pi `meshmonitor`, or
  `http://raspberrypi.local/` for the default). This works on iPhone and modern
  Android browsers and needs no router. Don't remember the hostname? Run
  `hostname` on the Pi.
- **Option A (phone hotspot):** some phones list connected devices and their IPs
  in the hotspot screen; otherwise `.local` (above) is the easy path.

### What works offline vs. what doesn't

**Works with no internet at all** (this is the whole point):

- The MeshMonitor dashboard, login, node list, map, and messaging.
- Sending/receiving on the mesh and all the seeded Electric Forest automations —
  these run on the Pi and the radio, which never needed the internet.

**Needs internet** (so these only work when the Pi is online via Option A, or at
home):

- The **first-time install** (the deployer downloads Docker and container images
  — do this at home before you leave).
- Pulling **updated** container images later.
- The map's background **tiles** if MeshMonitor fetches them from an online map
  service — the map *positions* still work, but tiles may not render until the
  Pi has internet once. Mesh data, nodes, and messaging are unaffected.

### Power: running on an EcoFlow River / solar generator

A Raspberry Pi sips power, which is why this works so well off-grid.

- **Draw:** a Pi 4 idles around **3–4W** (up to ~6W under load); a Pi 5 idles
  around **2.7–3W**. Add your USB-powered Meshtastic node and Wi-Fi/Bluetooth
  overhead and the whole setup pulls roughly **4–8W** in normal use. Call it
  ~5–6W average for runtime math.

- **Runtime per battery** (rough, at ~5W average draw; real-world usable energy
  is a bit below the rated Wh because of conversion losses, so these are
  conservative):

  | Power station (class) | Rated capacity | Approx. runtime at ~5W |
  | --- | --- | --- |
  | EcoFlow River 3 / River 2 | ~245–268 Wh | ~1.5–2 days |
  | EcoFlow River 2 Max | ~512 Wh | ~3.5–4 days |
  | EcoFlow River 2 Pro | ~768 Wh | ~5–6 days |

  Even a **small** solar panel (40–60W) in a few hours of sun makes far more than
  a Pi uses in a day, so with any sun you can run **indefinitely** — the battery
  is really just there to carry you overnight and through cloudy stretches.

- **Power the Pi from a USB-C or DC port, not the AC inverter.** Power stations
  have an **idle/eco auto-shutoff**: if the only thing plugged into the **AC**
  outlets draws very little (a few watts), the inverter decides nothing's there
  and **switches itself off**, killing your Pi. Using the unit's **USB-C** output
  (or a 12V DC output with a buck converter) avoids that entirely *and* skips the
  inverter's conversion loss, so you get more hours per charge. If you must use
  AC, disable the unit's auto-shutoff/eco setting in the EcoFlow app.

- **Use a quality 5V supply that can deliver enough current.** A Pi 4 wants a
  **5V / 3A** (15W) supply; a Pi 5 wants **5V / 5A** (the official 27W USB-C PD
  supply) to run at full speed. Underpowering the Pi causes the dreaded
  low-voltage warning, random reboots, and SD-card corruption — exactly the kind
  of "it worked at home but dies at camp" problem you want to avoid. Use the
  official Pi supply or a known-good USB-C cable rated for the current; thin or
  long cheap cables drop voltage and cause brownouts.

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

---

## Found a problem? Need help?

Stuck, or hit an error? **[Open a new issue](https://github.com/efmesh/meshmonitor-pi-deployer/issues/new/choose)** — you'll get a short, fill-in-the-blank form (no technical experience needed). There's one for "something went wrong" and a simpler one for "I'm stuck / I have a question."

The most helpful thing you can include is the **end of your install output** — scroll to the bottom of your terminal where it stopped or showed the summary box, and paste the last 30–40 lines. (Don't paste passwords; the deployer doesn't print them, but glance over it first.)

For questions about the mesh itself — node hardware, antennas, settings, or connecting at the Forest — the [efmesh.com](https://efmesh.com) guide and the [Electric Forest Discord](https://discord.gg/electricforest) are the place to go.
