#!/usr/bin/env bash
set -euo pipefail
WG_IF="${WG_IF:-wg0}"
WG_PORT="${WG_PORT:-51820}"
WG_DIR="${WG_DIR:-/etc/wireguard}"
PEER_DIR="$WG_DIR/peers"
fail=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n' "$label"
    fail=1
  fi
}

check "WireGuard service active" systemctl is-active --quiet "wg-quick@$WG_IF"
check "WireGuard interface exists" ip link show "$WG_IF"
check "IPv4 forwarding enabled" bash -c '[[ "$(sysctl -n net.ipv4.ip_forward)" == "1" ]]'
check "UDP listener configured" bash -c "wg show '$WG_IF' listen-port | grep -qx '$WG_PORT'"
check "Server public key exists" test -s "$WG_DIR/server.pub"
check "Persistent base config exists" test -s "$WG_DIR/$WG_IF.base.conf"

runtime_peers=$(wg show "$WG_IF" peers 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')
persisted_peers=0
if compgen -G "$PEER_DIR/*.peer" >/dev/null; then
  persisted_peers=$(find "$PEER_DIR" -maxdepth 1 -type f -name '*.peer' | wc -l | tr -d ' ')
fi
if [[ "$runtime_peers" == "$persisted_peers" ]]; then
  printf 'PASS  Runtime peers match persistent peer fragments (%s)\n' "$runtime_peers"
else
  printf 'FAIL  Runtime peers (%s) != persistent peers (%s)\n' "$runtime_peers" "$persisted_peers"
  fail=1
fi

printf '\nWireGuard summary:\n'
wg show "$WG_IF" 2>/dev/null || true
exit "$fail"
