#!/usr/bin/env sh
set -eu

PI_IP="${TARGET_PI_IP:-}"
PI_PASSWORD="${TARGET_PI_PASSWORD:-}"
RADIO_CONNECTION_TYPE="${RADIO_CONNECTION_TYPE:-${CONNECTION_TYPE:-wifi}}"
RADIO_CONNECTION_TYPE="$(printf '%s' "$RADIO_CONNECTION_TYPE" | tr '[:upper:]' '[:lower:]')"
RADIO_IP="${RADIO_IP:-}"
RADIO_MAC="${RADIO_MAC:-}"
PI_USERNAME="${PI_USERNAME:-pi}"
PI_SSH_PORT="${PI_SSH_PORT:-22}"
EF_CAMP="${EF_CAMP:-}"
EF_MORNING_MESSAGE="${EF_MORNING_MESSAGE:-}"
MESHMONITOR_ADMIN_PASSWORD="${MESHMONITOR_ADMIN_PASSWORD:-}"
FORCE_SEED="${FORCE_SEED:-false}"

if [ -z "$PI_IP" ]; then
  echo "TARGET_PI_IP is required"
  exit 1
fi

if [ -z "$PI_PASSWORD" ]; then
  echo "TARGET_PI_PASSWORD is required"
  exit 1
fi

if [ "$RADIO_CONNECTION_TYPE" != "wifi" ] && [ "$RADIO_CONNECTION_TYPE" != "bluetooth" ]; then
  echo "RADIO_CONNECTION_TYPE must be either 'wifi' or 'bluetooth'"
  exit 1
fi

# Electric Forest turnkey automation seeding inputs.
if [ -z "$EF_CAMP" ]; then
  echo "EF_CAMP is required (your camp / location label for the seeded messages)"
  exit 1
fi

if [ -z "$MESHMONITOR_ADMIN_PASSWORD" ]; then
  echo "MESHMONITOR_ADMIN_PASSWORD is required to seed MeshMonitor automations"
  exit 1
fi

if [ "$MESHMONITOR_ADMIN_PASSWORD" = "changeme" ]; then
  echo "MESHMONITOR_ADMIN_PASSWORD must not be the default 'changeme'"
  exit 1
fi

# Default the sunrise message to the camp-substituted greeting when unset.
if [ -z "$EF_MORNING_MESSAGE" ]; then
  EF_MORNING_MESSAGE="🌅 Good Morning from ${EF_CAMP}! ☀️🌲"
fi

if [ "$RADIO_CONNECTION_TYPE" = "wifi" ]; then
  if [ -z "$RADIO_IP" ]; then
    echo "RADIO_IP is required when RADIO_CONNECTION_TYPE=wifi"
    exit 1
  fi

  if ! echo "$RADIO_IP" | grep -Eq '^((25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$'; then
    echo "RADIO_IP must be a valid IPv4 address"
    exit 1
  fi
fi

if [ "$RADIO_CONNECTION_TYPE" = "bluetooth" ]; then
  if [ -z "$RADIO_MAC" ]; then
    echo "RADIO_MAC is required when RADIO_CONNECTION_TYPE=bluetooth"
    exit 1
  fi

  if ! echo "$RADIO_MAC" | grep -Eq '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'; then
    echo "RADIO_MAC must be in format AA:BB:CC:DD:EE:FF"
    exit 1
  fi
fi

cat > /workspace/ansible/inventory.ini <<EOF
[raspberry_pi]
pi_target ansible_host=$PI_IP ansible_user=$PI_USERNAME ansible_port=$PI_SSH_PORT ansible_connection=ssh ansible_ssh_pass=$PI_PASSWORD ansible_become_pass=$PI_PASSWORD
EOF

echo "Running deployment for $PI_IP with MeshMonitor radio mode: $RADIO_CONNECTION_TYPE"
# Pass EF seeding inputs as extra-vars via a JSON file so that arbitrary
# characters (emoji, quotes, spaces) in the camp and morning message survive
# without shell-quoting issues.
EF_EXTRA_VARS_FILE=/workspace/ansible/.ef_extra_vars.json
export EF_CAMP EF_MORNING_MESSAGE MESHMONITOR_ADMIN_PASSWORD FORCE_SEED
python3 - "$EF_EXTRA_VARS_FILE" <<'PYEOF'
import json, os, sys
data = {
    "ef_camp": os.environ.get("EF_CAMP", ""),
    "ef_morning_message": os.environ.get("EF_MORNING_MESSAGE", ""),
    "meshmonitor_admin_password": os.environ.get("MESHMONITOR_ADMIN_PASSWORD", ""),
    "ef_force_seed": os.environ.get("FORCE_SEED", "false"),
}
with open(sys.argv[1], "w") as fh:
    json.dump(data, fh)
PYEOF

rc=0
ANSIBLE_CONFIG=/workspace/ansible/ansible.cfg ansible-playbook \
  -e "meshmonitor_radio_connection_type=$RADIO_CONNECTION_TYPE" \
  -e "meshmonitor_radio_ip=$RADIO_IP" \
  -e "meshmonitor_radio_mac=$RADIO_MAC" \
  -e "@$EF_EXTRA_VARS_FILE" \
  /workspace/ansible/playbook.yml || rc=$?
rm -f "$EF_EXTRA_VARS_FILE"
exit "$rc"
