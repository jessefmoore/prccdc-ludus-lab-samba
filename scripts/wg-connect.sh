#!/usr/bin/env bash
# =============================================================================
# wg-connect.sh — bring up a CCDC2-scoped WireGuard tunnel and open the
# scoreboard. Scopes AllowedIPs to ONLY 10.51.0.0/16 so it never blackholes the
# client's own subnet. See docs/WIREGUARD-ACCESS.md.
#
# Usage:  ./wg-connect.sh [LUDUS_WG_CONF]   (default: ludus-wg.conf in cwd)
#   Get LUDUS_WG_CONF first:  ludus user wireguard --user JM > ludus-wg.conf
#   (or MCP/REST GET /user/wireguard?userID=JM)
# =============================================================================
set -euo pipefail
SRC="${1:-ludus-wg.conf}"
RANGE_SUBNET="10.51.0.0/16"
WG_SERVER="198.51.100.1/32"
IFACE="ccdc2"
DST="/etc/wireguard/${IFACE}.conf"

[[ -f "$SRC" ]] || { echo "!! $SRC not found. Run: ludus user wireguard --user JM > $SRC"; exit 1; }
grep -q "$RANGE_SUBNET" "$SRC" || cat <<EOF
!! WARNING: $SRC does not contain $RANGE_SUBNET.
   Your WG scope is stale — regenerate it (admin):
     ludus range assign --user JM --range CCDC2
     ludus user wireguard --user JM > $SRC
EOF

# Scope AllowedIPs to ONLY the range subnet (+ WG server /32) — never route the
# client's own subnet through the tunnel.
sed -E "s#^AllowedIPs =.*#AllowedIPs = ${WG_SERVER},${RANGE_SUBNET}#" "$SRC" \
  | sudo tee "$DST" >/dev/null
sudo chmod 600 "$DST"

sudo wg-quick down "$IFACE" 2>/dev/null || true
sudo wg-quick up "$IFACE"
sleep 2
echo "== tunnel =="; sudo wg show "$IFACE" | grep -E 'handshake|transfer' || true
echo "==> Opening the Quotient scoreboard (http://10.51.50.10/)"
xdg-open http://10.51.50.10/ 2>/dev/null || echo "   open http://10.51.50.10/ in your browser"
echo "==> Down when done:  sudo wg-quick down $IFACE"
