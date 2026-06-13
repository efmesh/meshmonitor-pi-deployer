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

# Configure-existing mode: skip the full provisioning (Docker, nginx, container
# deploy) and only (re)seed the Electric Forest automations on an already
# running MeshMonitor instance via the playbook's `configure` tag. The SSH
# connection still targets the Pi (TARGET_PI_IP / PI_SSH_PORT) as usual; the
# only extra thing we need is the MeshMonitor port to reach on 127.0.0.1.
CONFIGURE_EXISTING="${CONFIGURE_EXISTING:-false}"
CONFIGURE_EXISTING="$(printf '%s' "$CONFIGURE_EXISTING" | tr '[:upper:]' '[:lower:]')"
MESHMONITOR_HTTP_PORT="${MESHMONITOR_HTTP_PORT:-8080}"

if [ -z "$PI_IP" ]; then
  echo "TARGET_PI_IP is required"
  exit 1
fi

if [ -z "$PI_PASSWORD" ]; then
  echo "TARGET_PI_PASSWORD is required"
  exit 1
fi

if [ "$CONFIGURE_EXISTING" = "true" ]; then
  case "$MESHMONITOR_HTTP_PORT" in
    ''|*[!0-9]*)
      echo "MESHMONITOR_HTTP_PORT must be a port number when configuring an existing instance"
      exit 1
      ;;
  esac
fi

if [ "$CONFIGURE_EXISTING" != "true" ]; then
  if [ "$RADIO_CONNECTION_TYPE" != "wifi" ] && [ "$RADIO_CONNECTION_TYPE" != "bluetooth" ]; then
    echo "RADIO_CONNECTION_TYPE must be either 'wifi' or 'bluetooth'"
    exit 1
  fi
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

# MeshMonitor enforces an 8-character minimum; reject early with a clear message
# rather than failing deep in the seeding step (where a too-short password would
# leave the instance on the default 'changeme').
if [ "${#MESHMONITOR_ADMIN_PASSWORD}" -lt 8 ]; then
  echo "MESHMONITOR_ADMIN_PASSWORD must be at least 8 characters (MeshMonitor requirement)"
  exit 1
fi

# Default the sunrise message to the camp-substituted greeting when unset.
if [ -z "$EF_MORNING_MESSAGE" ]; then
  EF_MORNING_MESSAGE="🌅 Good Morning from ${EF_CAMP}! ☀️🌲"
fi

if [ "$RADIO_CONNECTION_TYPE" = "wifi" ] && [ "$CONFIGURE_EXISTING" != "true" ]; then
  if [ -z "$RADIO_IP" ]; then
    echo "RADIO_IP is required when RADIO_CONNECTION_TYPE=wifi"
    exit 1
  fi

  if ! echo "$RADIO_IP" | grep -Eq '^((25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$'; then
    echo "RADIO_IP must be a valid IPv4 address"
    exit 1
  fi
fi

if [ "$RADIO_CONNECTION_TYPE" = "bluetooth" ] && [ "$CONFIGURE_EXISTING" != "true" ]; then
  if [ -z "$RADIO_MAC" ]; then
    echo "RADIO_MAC is required when RADIO_CONNECTION_TYPE=bluetooth"
    exit 1
  fi

  if ! echo "$RADIO_MAC" | grep -Eq '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'; then
    echo "RADIO_MAC must be in format AA:BB:CC:DD:EE:FF"
    exit 1
  fi
fi

# Single-quote the password for the INI host line so spaces survive Ansible's
# shlex parsing, escaping any single quotes the password itself contains.
PI_PASSWORD_INI="$(printf '%s' "$PI_PASSWORD" | sed "s/'/'\\\\''/g")"
cat > /workspace/ansible/inventory.ini <<EOF
[raspberry_pi]
pi_target ansible_host=$PI_IP ansible_user=$PI_USERNAME ansible_port=$PI_SSH_PORT ansible_connection=ssh ansible_ssh_pass='$PI_PASSWORD_INI' ansible_become_pass='$PI_PASSWORD_INI'
EOF

if [ "$CONFIGURE_EXISTING" = "true" ]; then
  echo "Configuring existing MeshMonitor instance on $PI_IP at 127.0.0.1:$MESHMONITOR_HTTP_PORT"
else
  echo "Running deployment for $PI_IP with MeshMonitor radio mode: $RADIO_CONNECTION_TYPE"
fi
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
TAGS_ARG=""
if [ "$CONFIGURE_EXISTING" = "true" ]; then
  # Only run the seeding/configuration tasks against the existing instance.
  TAGS_ARG="--tags configure"
fi
ANSIBLE_CONFIG=/workspace/ansible/ansible.cfg ansible-playbook \
  $TAGS_ARG \
  -e "meshmonitor_radio_connection_type=$RADIO_CONNECTION_TYPE" \
  -e "meshmonitor_radio_ip=$RADIO_IP" \
  -e "meshmonitor_radio_mac=$RADIO_MAC" \
  -e "@$EF_EXTRA_VARS_FILE" \
  /workspace/ansible/playbook.yml || rc=$?
rm -f "$EF_EXTRA_VARS_FILE"
exit "$rc"
