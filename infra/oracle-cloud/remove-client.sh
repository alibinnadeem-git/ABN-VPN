#!/usr/bin/env bash
set -euo pipefail

# Usage: sudo ./remove-client.sh <client-name-or-public-key>
TARGET="${1:?client name or public key required}"
WG_IF="${WG_IF:-wg0}"
WG_DIR="${WG_DIR:-/etc/wireguard}"
PEER_DIR="$WG_DIR/peers"
BASE_CONF="$WG_DIR/$WG_IF.base.conf"
FINAL_CONF="$WG_DIR/$WG_IF.conf"
OUT_DIR="${OUT_DIR:-/root/client-configs}"

if [[ $EUID -ne 0 ]]; then echo "Run as root" >&2; exit 1; fi

PEER_FILE=""
if [[ -f "$PEER_DIR/$TARGET.peer" ]]; then
  PEER_FILE="$PEER_DIR/$TARGET.peer"
else
  for candidate in "$PEER_DIR"/*.peer; do
    [[ -e "$candidate" ]] || continue
    if grep -qsFx "PublicKey = $TARGET" "$candidate"; then
      PEER_FILE="$candidate"
      break
    fi
  done
fi

if [[ -z "$PEER_FILE" ]]; then echo "Peer not found: $TARGET" >&2; exit 1; fi
NAME=$(basename "$PEER_FILE" .peer)
PUB=$(awk -F' = ' '$1=="PublicKey" {print $2; exit}' "$PEER_FILE")

wg set "$WG_IF" peer "$PUB" remove || true
rm -f "$PEER_FILE" "$OUT_DIR/$NAME.conf"

{
  cat "$BASE_CONF"
  for peer in "$PEER_DIR"/*.peer; do
    [[ -e "$peer" ]] || continue
    printf '\n'
    cat "$peer"
  done
} > "$FINAL_CONF"
chmod 600 "$FINAL_CONF"
wg syncconf "$WG_IF" <(wg-quick strip "$WG_IF")

echo "Client revoked and removed from persistent config: $NAME"
