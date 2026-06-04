# Bluetooth Pairing Guide (Manual)

The deployer does not perform Bluetooth pairing automatically.

Use these steps to pair the Raspberry Pi onboard Bluetooth adapter to your LoRa radio before running deployment with `bluetooth`.

This guide assumes:

- Raspberry Pi OS without desktop UI
- You can access the Pi shell via local console or SSH over Wi-Fi/Ethernet for initial setup
- Your LoRa radio is powered on and in Bluetooth advertising/pairing mode

## 1. Prepare Raspberry Pi

1. On the Pi, install Bluetooth tools if needed:

```bash
sudo apt-get update
sudo apt-get install -y bluez bluez-tools
```

2. Ensure Bluetooth service is enabled:

```bash
sudo systemctl enable --now bluetooth
```

3. Open `bluetoothctl` on the Pi:

```bash
bluetoothctl
```

4. In the `bluetoothctl` prompt, run:

```text
power on
agent on
default-agent
```

## 2. Find the LoRa radio and pair from the Pi

1. Start scanning from the `bluetoothctl` prompt:

```text
scan on
```

2. Wait for your radio to appear in scan results and copy its BLE MAC address.

3. Stop scanning and pair/trust/connect the radio:

```text
scan off
pair <DEVICE_MAC>
trust <DEVICE_MAC>
connect <DEVICE_MAC>
```

If pairing prompts for authentication, follow the matching branch:

- Confirm passkey prompt:

```text
Confirm passkey 123456 (yes/no)
```

Compare the number to what the radio/app shows, then type `yes`.

- Enter PIN prompt:

```text
Enter PIN code:
```

Type the radio PIN (from device docs/app), then press Enter.

If you are unsure which prompt you have, do not continue until you confirm whether the radio expects numeric confirmation or a fixed PIN.

4. Confirm the radio state:

```text
info <DEVICE_MAC>
```

Look for:

- `Paired: yes`
- `Trusted: yes`
- `Connected: yes` (or reconnect at runtime if radio sleeps)

Save this `<DEVICE_MAC>` value. You must provide it as `RADIO_MAC` when running deployment in bluetooth mode.

## 3. Reconnect behavior (recommended)

Some radios disconnect when idle. You can reconnect from the Pi anytime:

```text
bluetoothctl
connect <DEVICE_MAC>
```

If needed, remove and re-pair:

```text
bluetoothctl
remove <DEVICE_MAC>
pair <DEVICE_MAC>
trust <DEVICE_MAC>
connect <DEVICE_MAC>
```

## 4. Run deployer with bluetooth mode

Use the regular run script and set MeshMonitor radio connection to `bluetooth` when prompted.

This selection configures MeshMonitor-to-radio transport only. The deployer still reaches the Pi over SSH.

## 5. Quick troubleshooting

1. If scan does not find the radio:

```bash
sudo systemctl restart bluetooth
rfkill list
```

If Bluetooth is blocked, unblock it:

```bash
sudo rfkill unblock bluetooth
```

2. If pair fails repeatedly, remove old records on the Pi and retry pairing.

3. If the radio changes BLE MAC after firmware updates, scan again and update the paired device.

4. Keep the radio close to the Pi during pairing.
