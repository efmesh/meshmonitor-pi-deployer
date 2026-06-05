# Electric Forest turnkey automations

This deployer seeds a fresh MeshMonitor instance with a turnkey set of Electric
Forest (EF) automations so an attendee's node is useful on the mesh the moment
it comes online — no manual settings tour required.

Everything seeded here is editable later in the MeshMonitor web UI under
**Settings → Automation**. The seeder only writes these settings once (tracked
by a seed-version marker on the Pi); see [Re-running and FORCE_SEED](#re-running-and-force_seed).

## What you provide

When you run `scripts/run.sh` (macOS/Linux) or `scripts/run.ps1` (Windows), you
are prompted for:

| Prompt | `.env` var | Required | Notes |
| --- | --- | --- | --- |
| Camp / area picker | `EF_CAMP` | Yes | Pick a known EF camp or type your own (e.g. `GA Loop 5 by the showers`). Baked into the auto-ack and sunrise messages. |
| MeshMonitor admin password | `MESHMONITOR_ADMIN_PASSWORD` | Yes | Set on first deploy. Must not be empty or `changeme`. |
| Sunrise morning message | `EF_MORNING_MESSAGE` | No | Defaults to `🌅 Good Morning from <CAMP>! ☀️🌲`. |
| Re-seed even if already seeded | `FORCE_SEED` | No | `true` to re-apply settings. Default `false`. |

The camp string is substituted literally into all seeded messages at deploy
time — MeshMonitor has no `{CAMP}` template variable, so the seeder bakes your
camp text directly into each message.

## Seeded automations

| Automation | What it does | Default | Notes |
| --- | --- | --- | --- |
| **Auto-ack** | Replies to "test"/"ping"/"check"-style messages with a hop/SNR/RSSI report mentioning your camp. | On, channels `0,2`, DM responses. | Covers direct, multihop, replies, and tapbacks. Regex avoids false-firing on phrases like "Hey test". |
| **Auto-ping** | Lets others DM `ping #` to request a ping test repeated # times. | On. 30s interval, max 20 pings, 60s timeout. | Airtime: capped at 20 pings to avoid flooding. |
| **Auto-responder** | Canned DM replies to `hey/hello/hi` → "hey", `ping` → "pong", `test` → "got your test". | On, DM channel. | Friendly first-contact responses. |
| **Auto-welcome** | DMs a one-time welcome the first time it sees a new node. | On, DM, up to 10 hops, waits for the node's name first. | **Airtime:** DMs *every* new node. In a dense mesh you may want this off — see below. |
| **Auto-time-sync** | Periodically pushes time to nodes that need it. | On, every 15 min, 24h expiration. | Node filter off (syncs all). |
| **Auto-key-management** | Auto-exchanges/purges PKC keys to keep DMs working. | On, every 60 min, auto-purge, max 3 exchanges. | |
| **Sunrise announce** | Posts the morning message to forest-chat at 6:05 AM. | On, cron `5 6 * * *`, channel index `2`. | See [Sunrise schedule](#sunrise-schedule). |
| **Display preferences** | Map centered on Double JJ Ranch (Rothbury, MI), miles/°F, 12h clock, `MM/DD/YYYY`. | — | Map center ≈ `43.754, -86.341`, zoom 14. |
| **Retention** | Message retention 30 days, max node age 168h (7 days), packet log off. | — | Keeps the DB lean for a festival-duration deployment. |

## efmesh channel assumptions

The seeded settings follow [efmesh.com's recommended channel
layout](https://efmesh.com/docs/recommended-settings.html):

- **Slot 0 = Primary**
- **Slot 2 = forest-chat**

Auto-ack listens on channels `0,2`, and the sunrise announce posts to
**forest-chat (slot 2)**. If your node's channel layout differs, update
`autoAckChannels` and `autoAnnounceChannelIndex` / `autoAnnounceChannelIndexes`
in the MeshMonitor UI after deploy.

## Sunrise schedule

The sunrise announce uses MeshMonitor's scheduled-announce feature with cron
`5 6 * * *` (06:05). The MeshMonitor container is configured with
`TZ=America/Detroit`, so the schedule fires at **6:05 AM Rothbury-local time**,
not UTC. Change the time in the UI (Settings → Automation → Announce) or by
editing `autoAnnounceSchedule`.

## Airtime considerations

LoRa airtime is shared and limited. Two seeded automations generate the most
traffic:

- **Auto-welcome** DMs every new node it sees. At a large gathering with many
  nodes this can add up. If you're in a dense part of the mesh, consider turning
  it off (Settings → Automation → Auto-Welcome) or lowering `autoWelcomeMaxHops`.
- **Auto-ping** can send up to 20 pings per request. It's capped, but be mindful
  if many people use it at once.

Auto-ack and the sunrise announce are low-volume by comparison.

## Re-running and FORCE_SEED

The seeder records the applied seed version in
`/opt/meshmonitor/.efmesh_seed_version` on the Pi. On reruns:

- If the marker's version is **≥** the current seed version and `FORCE_SEED` is
  not `true`, the seeder logs `Already seeded` and exits without changing
  anything (so your manual UI tweaks are preserved).
- Set `FORCE_SEED=true` (env or `.env`) to re-apply the seeded settings,
  overwriting any manual changes to those keys.

Because MeshMonitor's settings API silently ignores unrecognized keys, the seed
version is tracked via this Pi-side marker file rather than as a MeshMonitor
setting.

## Idempotent password handling

On first deploy the seeder logs in with the MeshMonitor default
(`admin`/`changeme`), changes the password to `MESHMONITOR_ADMIN_PASSWORD`, then
seeds. On later deploys it logs in directly with `MESHMONITOR_ADMIN_PASSWORD`. If
you change the admin password in the UI, update `MESHMONITOR_ADMIN_PASSWORD`
before re-running.
