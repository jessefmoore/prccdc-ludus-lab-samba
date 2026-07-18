# CCDC-RANGE-2 — Access URLs

Reach the range over WireGuard (Ludus `getWireguardConfig`; AllowedIPs include
10.51.0.0/16). First packet over WG is often dropped — warm the host:port, retry.

| Service | URL / endpoint | Login |
|---------|----------------|-------|
| WordPress | http://10.51.20.10 | AD users (authLdap) or `wpadmin` / `CCDC2-WP-Admin-2026!` |
| Snipe-IT | http://10.51.30.30 | first-run wizard |
| MantisBT | http://10.51.30.40/mantis/login_page.php | `administrator` / `root` (fresh) |
| Roundcube webmail | http://10.51.10.40 | AD user, e.g. `jsmith` / `CCDC2-User-2026!` |
| Authentik | http://10.51.30.20:9000 | `akadmin` / `CCDC2-Authentik-2026!` |
| Kibana (Elastic SIEM) | https://10.51.40.10:5601 | `elastic` / `elasticpassword` |
| File share | `\\10.51.10.30\Departments` | AD department members |
| Backup NAS | `\\10.51.40.20\backups`, `nfs 10.51.40.20:/srv/backups` | guest (lab) |
| Samba DC (LDAP) | `ldap://10.51.10.10` | `CCDC\svc_ldap` / `CCDC2-Svc-2026!` |
| RustDesk support | direct IP to any Linux host | unattended `CCDC2-RustDesk-2026!` |

SSH: domain-joined Linux hosts accept AD users (`jsmith`…); all hosts also accept
the Ludus local account (`getAnsibleInventory`). snipe01 SSH is governed by
Authentik once its outpost is finalized (`docs/AD-INTEGRATION.md`).
