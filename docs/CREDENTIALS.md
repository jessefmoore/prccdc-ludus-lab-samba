# CCDC-RANGE-2 — Master Credential Sheet

All passwords are role defaults (overridable via `role_vars`/`global_role_vars`).
**Rotate before any non-lab use. Keep this repo private.**

## Active Directory (Samba DC — ccdc.local)
| Account | Password | Notes |
|---------|----------|-------|
| `Administrator` | `CCDC2-Admin-2026!` | Domain admin (set at provision) |
| `ccdcuser` | `CCDC2-User-2026!` | Plain domain user |
| `svc_ldap` | `CCDC2-Svc-2026!` | LDAP bind account for apps |
| `jsmith` / `agarcia` / `bwong` / `csingh` / `dpatel` | `CCDC2-User-2026!` | Employees (IT/HR/Finance/Sales/Engineering), each with `mail=<user>@ccdc.local` |

Department groups: HR, Finance, IT, Sales, Engineering.

## Databases (central MariaDB @ 10.51.30.10)
| DB | User | Password |
|----|------|----------|
| root | root | `CCDC2-DBRoot-2026!` (socket/local) |
| `wordpress` | `wp_user` | `CCDC2-WP-2026!` |
| `snipeit` | `snipeit` | `CCDC2-Snipe-2026!` |
| `mantisbt` | `mantis` | `CCDC2-Mantis-2026!` |

## Applications
| Service | URL | Login |
|---------|-----|-------|
| WordPress | http://10.51.20.10 | `wpadmin` / `CCDC2-WP-Admin-2026!` |
| Authentik | http://10.51.30.20:9000 | `akadmin` / `CCDC2-Authentik-2026!` |
| Snipe-IT | http://10.51.30.30 | first-run setup wizard creates admin |
| MantisBT | http://10.51.30.40/mantis/ | fresh install: `administrator` / `root` |
| Roundcube (mail) | http://10.51.10.40 | any AD user, e.g. `jsmith` / `CCDC2-User-2026!` |
| Elastic/Kibana | https://10.51.40.10:5601 | `elastic` / `elasticpassword` |
| RustDesk (support) | direct-IP to any host | unattended pw `CCDC2-RustDesk-2026!` |

## Backup / infra
| Thing | Value |
|-------|-------|
| Authentik bootstrap token | `CCDC2-Authentik-Token-2026-abcdef0123456789` |
| Authentik Postgres pw | `CCDC2-Authentik-PG-2026!` |
| restic repo pw (nas01) | `CCDC2-Restic-2026!` |
| SMB backup share | `\\10.51.40.20\backups` (guest, lab) |

## Host SSH (from Ludus inventory)
Ubuntu VMs `localuser` / `password`; Debian VMs `debian` / `debian`; Windows WinRM
`localuser` / `password`. Domain-joined Linux hosts also accept AD users over SSH.
Get exact values via Ludus `getAnsibleInventory`.
