# Reaching CCDC2 over WireGuard (open the scoreboard from your box)

How to get on the CCDC2 range network (`10.51.0.0/16`) from a Linux client (e.g.
a Kali box) and open the **Quotient scoreboard at http://10.51.50.10/** — plus any
other range service.

## The one-liner (TL;DR)
Once you have a working `ccdc2.conf` (see setup below):
```bash
sudo wg-quick up ccdc2 && xdg-open http://10.51.50.10/
```
Tear down when done: `sudo wg-quick down ccdc2`

---

## Two gotchas that will bite you

**1. Your WireGuard config must include `10.51.0.0/16`.** Ludus builds a user's WG
scope from the ranges assigned to them, and it can go **stale** (a freshly-created
range may be missing). If `AllowedIPs` has no `10.51.0.0/16`, **assign the range to
the user to regenerate it** (admin):
```bash
ludus range assign --user JM --range CCDC2     # API: POST /ranges/assign/JM/CCDC2
ludus user wireguard --user JM                 # re-fetch; now includes 10.51.0.0/16
```

**2. Do NOT route your own subnet through the tunnel.** If your client is itself a
Ludus range VM (this Kali is `10.2.10.13`), the raw Ludus config's `AllowedIPs`
lists *every* range including `10.2.0.0/16`. Routing `10.2.0.0/16` into the tunnel
**blackholes your own LAN/gateway** and you lose connectivity. **Scope AllowedIPs to
just the CCDC2 subnet** (+ the WG server's `/32`).

---

## Setup (once)
```bash
# 1. Get your Ludus WireGuard config
ludus user wireguard --user JM > ludus-wg.conf
#   (or via MCP/REST: GET /user/wireguard?userID=JM)

# 2. Make a CCDC2-scoped copy: keep the [Interface], but replace AllowedIPs with
#    ONLY the range subnet + the WG server /32 (see gotcha #2).
sed -E 's#^AllowedIPs =.*#AllowedIPs = 198.51.100.1/32,10.51.0.0/16#' ludus-wg.conf \
  | sudo tee /etc/wireguard/ccdc2.conf >/dev/null
sudo chmod 600 /etc/wireguard/ccdc2.conf
```

`/etc/wireguard/ccdc2.conf` should look like:
```ini
[Interface]
PrivateKey = <your key from ludus user wireguard>
Address = 198.51.100.2/32

[Peer]
PublicKey = <ludus server key>
Endpoint = 192.168.0.193:51820
AllowedIPs = 198.51.100.1/32,10.51.0.0/16
PersistentKeepalive = 25
```

## Use it
```bash
sudo wg-quick up ccdc2                 # bring the tunnel up
sudo wg show ccdc2                      # confirm: "latest handshake" + bytes received
xdg-open http://10.51.50.10/            # open the Quotient scoreboard
sudo wg-quick down ccdc2               # done
```

> **This range drops the FIRST packet to each host** — so the first hit to any IP
> (or right after a redeploy, while the router's conntrack resets) will fail, then
> work on retry. `scripts/wg-connect.sh` warms the scoreboard for you; in a browser,
> just refresh once or twice. Test with TCP, not ping (the routers drop ICMP):
> `for i in $(seq 5); do curl -sf -o /dev/null http://10.51.50.10/ && { echo up; break; }; sleep 2; done`

## Troubleshooting
- **Nothing in `10.51` reachable + `wg show` shows bytes sent but ~none received:**
  the range is mid-deploy (conntrack resetting) or the WG scope is stale. Wait for
  `rangeState: SUCCESS`, ensure the range is assigned to you
  (`ludus range assign --user JM --range CCDC2`), bounce the tunnel, and warm-retry.
- **Client is itself inside a Ludus range** (e.g. a Kali at `10.2.x`): it still
  works, but the asymmetric return path is extra sensitive to the first-packet drop —
  warm each host with a few retries. A fully external client is the smoothest.
- **Reliable no-WG fallback:** open the scoreboard from a range host via the Proxmox
  console — `CCDC2-desk01` (10.51.10.20) → Console → browse `http://10.51.50.10/`.

## Other CCDC2 URLs (all over the same tunnel)
| Service | URL |
|---------|-----|
| **Quotient scoreboard** | http://10.51.50.10/ (admin `admin` / `CCDC2-Score-Admin-2026!`) |
| WordPress | http://10.51.20.10/ |
| SnipeIT | http://10.51.30.30/ |
| MantisBT | http://10.51.30.40/mantis/ |
| Roundcube webmail | http://10.51.10.40/ |
| Authentik | http://10.51.30.20:9000/ |
| Kibana (Elastic SIEM) | https://10.51.40.10:5601/ |

See `docs/ACCESS-URLS.md` for the full list and credentials.
