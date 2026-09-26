#!/usr/bin/env bash
set -euo pipefail

# Installs a systemd timer that sends PUBLIC-SAFE WireGuard status to Netlify.
# Usage:
#   sudo ./install-heartbeat.sh CONTROL_PLANE_URL HEARTBEAT_TOKEN [NODE_ID]
# Example:
#   sudo ./install-heartbeat.sh https://abn-vpn.netlify.app '<secret>' us-sanjose-1

CONTROL_PLANE_URL="${1:?control plane URL required}"
HEARTBEAT_TOKEN="${2:?heartbeat token required}"
NODE_ID="${3:-us-sanjose-1}"
WG_IF="${WG_IF:-wg0}"

if [[ $EUID -ne 0 ]]; then echo "Run as root" >&2; exit 1; fi
if [[ ! "$NODE_ID" =~ ^[a-zA-Z0-9._-]{1,64}$ ]]; then echo "Invalid node ID" >&2; exit 1; fi
CONTROL_PLANE_URL="${CONTROL_PLANE_URL%/}"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl
install -d -m 700 /etc/abn-vpn

cat > /etc/abn-vpn/heartbeat.env <<ENV
ABN_CONTROL_PLANE_URL=$CONTROL_PLANE_URL
ABN_HEARTBEAT_TOKEN=$HEARTBEAT_TOKEN
ABN_NODE_ID=$NODE_ID
WG_IF=$WG_IF
ENV
chmod 600 /etc/abn-vpn/heartbeat.env

cat > /usr/local/sbin/abn-vpn-heartbeat <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
: "${ABN_CONTROL_PLANE_URL:?}"
: "${ABN_HEARTBEAT_TOKEN:?}"
: "${ABN_NODE_ID:?}"
WG_IF="${WG_IF:-wg0}"

if ! systemctl is-active --quiet "wg-quick@$WG_IF"; then
  peer_count=0
  active_peer_count=0
else
  peer_count=$(wg show "$WG_IF" peers 2>/dev/null | wc -w | tr -d ' ')
  now=$(date +%s)
  active_peer_count=$(wg show "$WG_IF" latest-handshakes 2>/dev/null | awk -v now="$now" '$2 > 0 && (now-$2) <= 180 {n++} END {print n+0}')
fi

payload=$(printf '{"nodeId":"%s","interface":"%s","peerCount":%d,"activePeerCount":%d,"version":"0.5"}' \
  "$ABN_NODE_ID" "$WG_IF" "$peer_count" "$active_peer_count")

curl --fail --silent --show-error \
  --connect-timeout 5 --max-time 10 --retry 2 \
  -H "Authorization: Bearer $ABN_HEARTBEAT_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$payload" \
  "$ABN_CONTROL_PLANE_URL/api/node-heartbeat" >/dev/null
SCRIPT
chmod 700 /usr/local/sbin/abn-vpn-heartbeat

cat > /etc/systemd/system/abn-vpn-heartbeat.service <<'UNIT'
[Unit]
Description=ABN VPN outbound node heartbeat
After=network-online.target wg-quick@wg0.service
Wants=network-online.target

[Service]
Type=oneshot
EnvironmentFile=/etc/abn-vpn/heartbeat.env
ExecStart=/usr/local/sbin/abn-vpn-heartbeat
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadOnlyPaths=/etc/wireguard
UNIT

cat > /etc/systemd/system/abn-vpn-heartbeat.timer <<'UNIT'
[Unit]
Description=Send ABN VPN node heartbeat every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
RandomizedDelaySec=5s
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now abn-vpn-heartbeat.timer
systemctl start abn-vpn-heartbeat.service

echo "Outbound heartbeat installed for node: $NODE_ID"
echo "No inbound health-check port was opened."
