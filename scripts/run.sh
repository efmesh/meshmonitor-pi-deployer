#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$PROJECT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
fi

DEFAULT_TARGET_PI_IP="${TARGET_PI_IP:-}"
if [[ -n "$DEFAULT_TARGET_PI_IP" ]]; then
  read -rp "Pi IP address [$DEFAULT_TARGET_PI_IP]: " TARGET_PI_IP_INPUT
  TARGET_PI_IP="${TARGET_PI_IP_INPUT:-$DEFAULT_TARGET_PI_IP}"
else
  read -rp "Pi IP address: " TARGET_PI_IP
fi

DEFAULT_PI_USERNAME="${PI_USERNAME:-pi}"
read -rp "Pi SSH username [$DEFAULT_PI_USERNAME]: " PI_USERNAME_INPUT
PI_USERNAME="${PI_USERNAME_INPUT:-$DEFAULT_PI_USERNAME}"

TARGET_PI_PASSWORD_VALUE="${TARGET_PI_PASSWORD:-}"
if [[ -n "$TARGET_PI_PASSWORD_VALUE" ]]; then
  read -rsp "Pi password [press Enter to use TARGET_PI_PASSWORD from .env]: " TARGET_PI_PASSWORD_INPUT
  TARGET_PI_PASSWORD="${TARGET_PI_PASSWORD_INPUT:-$TARGET_PI_PASSWORD_VALUE}"
else
  read -rsp "Pi password: " TARGET_PI_PASSWORD
fi
echo
DEFAULT_RADIO_CONNECTION_TYPE="${RADIO_CONNECTION_TYPE:-wifi}"
read -rp "MeshMonitor radio connection (wifi/bluetooth) [$DEFAULT_RADIO_CONNECTION_TYPE]: " RADIO_CONNECTION_TYPE
RADIO_CONNECTION_TYPE="${RADIO_CONNECTION_TYPE:-$DEFAULT_RADIO_CONNECTION_TYPE}"
RADIO_CONNECTION_TYPE="${RADIO_CONNECTION_TYPE,,}"

RADIO_IP_VALUE="${RADIO_IP:-}"
if [[ "$RADIO_CONNECTION_TYPE" == "wifi" ]]; then
  if [[ -n "$RADIO_IP_VALUE" ]]; then
    read -rp "LoRa radio IP address [$RADIO_IP_VALUE]: " RADIO_IP_INPUT
    RADIO_IP_VALUE="${RADIO_IP_INPUT:-$RADIO_IP_VALUE}"
  else
    read -rp "LoRa radio IP address: " RADIO_IP_INPUT
    RADIO_IP_VALUE="$RADIO_IP_INPUT"
  fi
fi

RADIO_MAC_VALUE="${RADIO_MAC:-}"
if [[ "$RADIO_CONNECTION_TYPE" == "bluetooth" ]]; then
  if [[ -n "$RADIO_MAC_VALUE" ]]; then
    read -rp "LoRa radio MAC (AA:BB:CC:DD:EE:FF) [$RADIO_MAC_VALUE]: " RADIO_MAC_INPUT
    RADIO_MAC_VALUE="${RADIO_MAC_INPUT:-$RADIO_MAC_VALUE}"
  else
    read -rp "LoRa radio MAC (AA:BB:CC:DD:EE:FF): " RADIO_MAC_INPUT
    RADIO_MAC_VALUE="$RADIO_MAC_INPUT"
  fi
fi

# Electric Forest turnkey automations --------------------------------------------
# Camp picker: pick a known Electric Forest camp/area or type your own. The
# selection is baked into the seeded auto-ack / sunrise messages at deploy time.
EF_CAMPS=(
  "GA Campgrounds"
  "Good Life Village"
  "Camp Higher Love"
  "Maplewoods"
  "Lucky Lake"
  "The Back 40"
)
EF_CAMP_DEFAULT="${EF_CAMP:-}"
echo
echo "Which Electric Forest camp / area is this node at?"
idx=1
for camp in "${EF_CAMPS[@]}"; do
  echo "  $idx) $camp"
  idx=$((idx + 1))
done
echo "  $idx) Other (type your own, e.g. \"GA Loop 5 by the showers\")"
OTHER_INDEX="$idx"

if [[ -n "$EF_CAMP_DEFAULT" ]]; then
  read -rp "Camp [$EF_CAMP_DEFAULT]: " EF_CAMP_CHOICE
else
  read -rp "Camp (1-$OTHER_INDEX): " EF_CAMP_CHOICE
fi

if [[ -z "$EF_CAMP_CHOICE" && -n "$EF_CAMP_DEFAULT" ]]; then
  EF_CAMP="$EF_CAMP_DEFAULT"
elif [[ "$EF_CAMP_CHOICE" == "$OTHER_INDEX" ]]; then
  read -rp "Enter your camp / location: " EF_CAMP
elif [[ "$EF_CAMP_CHOICE" =~ ^[0-9]+$ ]] && (( EF_CAMP_CHOICE >= 1 && EF_CAMP_CHOICE <= ${#EF_CAMPS[@]} )); then
  EF_CAMP="${EF_CAMPS[$((EF_CAMP_CHOICE - 1))]}"
else
  # Treat any free-text entry as a custom camp name.
  EF_CAMP="$EF_CAMP_CHOICE"
fi

while [[ -z "${EF_CAMP// /}" ]]; do
  read -rp "Camp / location cannot be empty. Enter your camp: " EF_CAMP
done
echo "Camp set to: $EF_CAMP"

# MeshMonitor admin password (required by the seeder). Silent input.
EF_MORNING_DEFAULT="${EF_MORNING_MESSAGE:-🌅 Good Morning from ${EF_CAMP}! ☀️🌲}"
while true; do
  read -rsp "MeshMonitor admin password to set (required, not 'changeme'): " MESHMONITOR_ADMIN_PASSWORD
  echo
  if [[ -z "$MESHMONITOR_ADMIN_PASSWORD" ]]; then
    echo "Admin password cannot be empty."
  elif [[ "$MESHMONITOR_ADMIN_PASSWORD" == "changeme" ]]; then
    echo "Admin password must not be the default 'changeme'."
  elif [[ "${#MESHMONITOR_ADMIN_PASSWORD}" -lt 8 ]]; then
    echo "Admin password must be at least 8 characters (MeshMonitor requirement)."
  else
    break
  fi
done

# Sunrise morning message (optional; default substitutes the camp).
read -rp "Sunrise morning message [$EF_MORNING_DEFAULT]: " EF_MORNING_INPUT
EF_MORNING_MESSAGE="${EF_MORNING_INPUT:-$EF_MORNING_DEFAULT}"

DEPLOYER_IMAGE_NAME="${DEPLOYER_IMAGE_NAME:-meshmonitor-deployer:latest}"

docker build -t "$DEPLOYER_IMAGE_NAME" "$PROJECT_DIR"
docker run --rm \
  -e TARGET_PI_IP="$TARGET_PI_IP" \
  -e TARGET_PI_PASSWORD="$TARGET_PI_PASSWORD" \
  -e RADIO_CONNECTION_TYPE="$RADIO_CONNECTION_TYPE" \
  -e RADIO_IP="$RADIO_IP_VALUE" \
  -e RADIO_MAC="$RADIO_MAC_VALUE" \
  -e PI_USERNAME="${PI_USERNAME:-pi}" \
  -e PI_SSH_PORT="${PI_SSH_PORT:-22}" \
  -e EF_CAMP="$EF_CAMP" \
  -e EF_MORNING_MESSAGE="$EF_MORNING_MESSAGE" \
  -e MESHMONITOR_ADMIN_PASSWORD="$MESHMONITOR_ADMIN_PASSWORD" \
  -e FORCE_SEED="${FORCE_SEED:-false}" \
  -e MESHMONITOR_IMAGE="${MESHMONITOR_IMAGE:-ghcr.io/yeraze/meshmonitor:latest}" \
  -e MESHMONITOR_HTTP_PORT="${MESHMONITOR_HTTP_PORT:-8080}" \
  -e MESHTASTIC_BLE_BRIDGE_IMAGE="${MESHTASTIC_BLE_BRIDGE_IMAGE:-ghcr.io/yeraze/meshtastic-ble-bridge:latest}" \
  -e MESHTASTIC_BLE_BRIDGE_PORT="${MESHTASTIC_BLE_BRIDGE_PORT:-4403}" \
  "$DEPLOYER_IMAGE_NAME"
