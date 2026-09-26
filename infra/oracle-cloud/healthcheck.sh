#!/usr/bin/env bash
set -euo pipefail
WG_IF="${WG_IF:-wg0}"
systemctl is-active --quiet "wg-quick@$WG_IF"
wg show "$WG_IF"
