# ccdc2_rustdesk

Installs the **RustDesk** remote-support client on Linux hosts (the desktop and
Linux servers). Enables the service, sets a permanent unattended-access password,
and turns on **direct-IP access** so an admin on the range/WireGuard LAN can
connect straight to a host's IP without a public ID/relay server.

## Vars
- `ccdc2_rustdesk_version` (default 1.4.9) / `ccdc2_rustdesk_deb_url`
- `ccdc2_rustdesk_unattended_password` (default `CCDC2-RustDesk-2026!`)
- `ccdc2_rustdesk_relay_host` / `_relay_key` — optional self-hosted hbbs/hbbr.

## Support workflow
From a RustDesk client, use **direct IP access**: enter the target host's IP
(e.g. `10.51.10.20`) and the unattended password. Get a host's RustDesk ID with
`rustdesk --get-id` on that host.

## Verify
```
systemctl status rustdesk
rustdesk --get-id
```
