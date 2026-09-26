#!/usr/bin/env bash
set -euo pipefail

# Run as root on Ubuntu 22.04/24.04.
WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_ADDRESS="${WG_ADDRESS:-10.77.0.1/24}"
WG_DIR="${WG_DIR:-/etc/wireguard}"
PEER_DIR="$WG_DIR/peers"
BASE_CONF="$WG_DIR/$WG_IF.base.conf"
FINAL_CONF="$WG_DIR/$WG_IF.conf"

if [[ $EUID -ne 0 ]]; then echo "Run as root" >&2; exit 1; fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard qrencode ufw
install -d -m 700 "$WG_DIR" "$PEER_DIR" /root/client-configs

if [[ ! -f "$WG_DIR/server.key" ]]; then
  umask 077
  wg genkey | tee "$WG_DIR/server.key" | wg pubkey > "$WG_DIR/server.pub"
fi
chmod 600 "$WG_DIR/server.key"
chmod 644 "$WG_DIR/server.pub"

PUB_IF=$(ip route show default | awk '/default/ {print $5; exit}')
if [[ -z "$PUB_IF" ]]; then echo "Could not determine public interface" >&2; exit 1; fi
SERVER_PRIV=$(cat "$WG_DIR/server.key")

cat > "$BASE_CONF" <<CONF
[Interface]
Address = $WG_ADDRESS
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIV
SaveConfig = false
PostUp = nft add table ip abn_vpn; nft 'add chain ip abn_vpn postrouting { type nat hook postrouting priority 100; }'; nft add rule ip abn_vpn postrouting oifname "$PUB_IF" masquerade
PostDown = nft delete table ip abn_vpn
CONF
chmod 600 "$BASE_CONF"

# Rebuild the persistent runtime config from the interface base plus peer fragments.
{
  cat "$BASE_CONF"
  for peer in "$PEER_DIR"/*.peer; do
    [[ -e "$peer" ]] || continue
    printf '\n'
    cat "$peer"
  done
} > "$FINAL_CONF"
chmod 600 "$FINAL_CONF"

cat > /etc/sysctl.d/99-abn-vpn.conf <<SYSCTL
net.ipv4.ip_forward=1
SYSCTL
sysctl --system >/dev/null

ufw allow OpenSSH
ufw allow "${WG_PORT}/udp"
ufw route allow in on "$WG_IF" out on "$PUB_IF"
ufw route allow in on "$PUB_IF" out on "$WG_IF"
ufw --force enable

systemctl enable "wg-quick@$WG_IF"
if systemctl is-active --quiet "wg-quick@$WG_IF"; then
  systemctl restart "wg-quick@$WG_IF"
else
  systemctl start "wg-quick@$WG_IF"
fi

echo "WireGuard initialized."
echo "Server public key: $(cat "$WG_DIR/server.pub")"
echo "UDP port: $WG_PORT"
echo "Public interface: $PUB_IF"
echo "IMPORTANT: Also allow UDP $WG_PORT in the Oracle VCN Security List or NSG."
