# CCDC-RANGE-2 — Network

Behind a Ludus native Debian router (`10.51.10.254`). IPs `10.51.<vlan>.<octet>`.

## VLANs
| VLAN | Purpose | Hosts |
|------|---------|-------|
| 10 | Corporate | dc01 (.10), desk01 (.20), fs01 (.30), mail01 (.40) |
| 20 | DMZ | web01 (.10) |
| 30 | Internal services | db01 (.10), auth01 (.20), snipe01 (.30), tick01 (.40) |
| 40 | Security / Backup | siem01 (.10), nas01 (.20) |

## DNS
Every Linux host uses the **Samba DC (10.51.10.10)** as its resolver
(`primary_dns_server`), so `ccdc.local` and its SRV records resolve. The DC's
Samba internal DNS forwards non-AD queries to `8.8.8.8`. `fs01` (Windows) points at
the DC via `ccdc2_fileshare`.

## Build-time posture
Flat / **ACCEPT** in all directions (`inter_vlan_default`, `external_default`,
`wireguard_vlan_default`) so every service + AD dependency resolves during the
build. For a competition, harden afterward — e.g. restrict inter-VLAN to only the
required flows:
- VLAN10→10.51.10.10: 53/88/389/445/636 (AD)
- any→db01:3306 only from web01/snipe01/tick01
- any→siem01:8220/5601 (Fleet/Kibana) from agents/admins
- DMZ web01:80 exposed; internal services not reachable from DMZ except DB
Apply via the range config `network` rules, then redeploy.

## Key ports
53 DNS · 88 Kerberos · 389/636 LDAP · 445 SMB · 25/143/465/587/993 mail ·
80 web (WordPress/SnipeIT/Mantis/Roundcube) · 3306 MariaDB · 9000/9443 Authentik ·
389/636 Authentik LDAP outpost · 5601 Kibana · 8220 Fleet · 2049 NFS · 21115-21119 RustDesk.
