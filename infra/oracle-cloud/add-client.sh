#!/usr/bin/env bash
set -euo pipefail

# Usage: sudo ./add-client.sh ali-iphone 10.77.0.2/32 SERVER_PUBLIC_IP_OR_DNS
NAME="${1:?client name required}"
CLIENT_IP="${2:?client tunnel IP required, e.g. 10.77.0.2/32}"
ENDPOINT="${3:?server public IP/DNS required}"
WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_DIR="${WG_DIR:-/etc/wireguard}"
PEER_DIR="$WG_DIR/peers"
BASE_CONF="$WG_DIR/$WG_IF.base.conf"
FINAL_CONF="$WG_DIR/$WG_IF.conf"
OUT_DIR="${OUT_DIR:-/root/client-configs}"
DNS="${DNS:-1.1.1.1}"

if [[ $EUID -ne 0 ]]; then echo "Run as root" >&2; exit 1; fi
if [[ ! "$NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then echo "Client name may contain only letters, numbers, dot, underscore, and dash" >&2; exit 1; fi
if [[ ! -s "$BASE_CONF" || ! -s "$WG_DIR/server.pub" ]]; then echo "Run init-wireguard.sh first" >&2; exit 1; fi

install -d -m 700 "$PEER_DIR" "$OUT_DIR"
PEER_FILE="$PEER_DIR/$NAME.peer"
CLIENT_CONF="$OUT_DIR/$NAME.conf"
if [[ -e "$PEER_FILE" || -e "$CLIENT_CONF" ]]; then echo "Client '$NAME' already exists" >&2; exit 1; fi
if grep -RqsFx "AllowedIPs = $CLIENT_IP" "$PEER_DIR" 2>/dev/null; then echo "Tunnel IP $CLIENT_IP is already assigned" >&2; exit 1; fi

umask 077
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(printf '%s' "$CLIENT_PRIV" | wg pubkey)
SERVER_PUB=$(cat "$WG_DIR/server.pub")

cat > "$PEER_FILE" <<PEER
# ABN-VPN client: $NAME
[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = $CLIENT_IP
PEER
chmod 600 "$PEER_FILE"

{
  cat "$BASE_CONF"
  for peer in "$PEER_DIR"/*.peer; do
    [[ -e "$peer" ]] || continue
    printf '\n'
    cat "$peer"
  done
} > "$FINAL_CONF"
chmod 600 "$FINAL_CONF"

# Apply the persistent config without taking the interface down.
wg syncconf "$WG_IF" <(wg-quick strip "$WG_IF")

cat > "$CLIENT_CONF" <<CONF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = $CLIENT_IP
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $ENDPOINT:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CONF
chmod 600 "$CLIENT_CONF"

echo "Client created and persisted: $NAME"
echo "Config: $CLIENT_CONF"
echo "WireGuard public key: $CLIENT_PUB"
echo "Scan this QR in the WireGuard mobile app:"
qrencode -t ansiutf8 < "$CLIENT_CONF"
