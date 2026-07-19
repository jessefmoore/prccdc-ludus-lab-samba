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

> First packet over a fresh tunnel is sometimes dropped — if a probe fails, retry.
> Test reachability with TCP, not ping (the range routers drop ICMP):
> `timeout 5 bash -c 'echo > /dev/tcp/10.51.50.10/80' && echo up`

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
