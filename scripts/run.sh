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
  -e MESHMONITOR_IMAGE="${MESHMONITOR_IMAGE:-ghcr.io/yeraze/meshmonitor:latest}" \
  -e MESHMONITOR_HTTP_PORT="${MESHMONITOR_HTTP_PORT:-8080}" \
  -e MESHTASTIC_BLE_BRIDGE_IMAGE="${MESHTASTIC_BLE_BRIDGE_IMAGE:-ghcr.io/meshtastic/meshtastic-ble-bridge:latest}" \
  -e MESHTASTIC_BLE_BRIDGE_PORT="${MESHTASTIC_BLE_BRIDGE_PORT:-4403}" \
  "$DEPLOYER_IMAGE_NAME"
