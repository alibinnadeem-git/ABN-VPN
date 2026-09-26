#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for the first ABN VPN node.
# Usage:
#   sudo ./bootstrap-first-node.sh PUBLIC_IP_OR_DNS [CLIENT_NAME] [CLIENT_TUNNEL_IP]
# Example:
#   sudo ./bootstrap-first-node.sh 203.0.113.10 ali-iphone 10.77.0.2/32

ENDPOINT="${1:?public IP or DNS name required}"
CLIENT_NAME="${2:-ali-iphone}"
CLIENT_IP="${3:-10.77.0.2/32}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WG_PORT="${WG_PORT:-51820}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0 PUBLIC_IP_OR_DNS [CLIENT_NAME] [CLIENT_TUNNEL_IP]" >&2
  exit 1
fi

chmod +x "$SCRIPT_DIR/init-wireguard.sh" "$SCRIPT_DIR/add-client.sh" "$SCRIPT_DIR/healthcheck.sh" "$SCRIPT_DIR/install-heartbeat.sh"
"$SCRIPT_DIR/init-wireguard.sh"
"$SCRIPT_DIR/add-client.sh" "$CLIENT_NAME" "$CLIENT_IP" "$ENDPOINT"

if [[ -n "${ABN_CONTROL_PLANE_URL:-}" && -n "${ABN_HEARTBEAT_TOKEN:-}" ]]; then
  "$SCRIPT_DIR/install-heartbeat.sh" "$ABN_CONTROL_PLANE_URL" "$ABN_HEARTBEAT_TOKEN" "${ABN_NODE_ID:-us-sanjose-1}"
else
  echo "Heartbeat not installed yet. Set ABN_CONTROL_PLANE_URL and ABN_HEARTBEAT_TOKEN, then run install-heartbeat.sh."
fi

cat <<JSON

ABN VPN first node bootstrap complete.

Health monitoring uses an OUTBOUND heartbeat; no inbound health port is required.

Register this PUBLIC-SAFE node metadata in Netlify as VPN_NODES_JSON:
[{"id":"us-sanjose-1","name":"US West — San Jose","region":"us-sanjose-1","provider":"Oracle Cloud","status":"online","endpoint":"${ENDPOINT}:${WG_PORT}"}]

Do NOT place any WireGuard private keys in Netlify.
Client config: /root/client-configs/${CLIENT_NAME}.conf
Server public key: $(cat /etc/wireguard/server.pub)
JSON
