# CCDC-RANGE-2 (Ludus)

![Ludus](https://img.shields.io/badge/Ludus-range-1f6feb)
![Ansible](https://img.shields.io/badge/Ansible-12%20custom%20roles-EE0000?logo=ansible&logoColor=white)
![Samba AD](https://img.shields.io/badge/DC-Samba%20AD-751A57)
![VMs](https://img.shields.io/badge/VMs-12-informational)
![Authentik](https://img.shields.io/badge/SSO-Authentik-FD4B2D)
![Elastic SIEM](https://img.shields.io/badge/SIEM-Elastic-005571?logo=elastic&logoColor=white)
![Deploy](https://img.shields.io/badge/deploy-SUCCESS-2ea44f)
![License](https://img.shields.io/badge/license-MIT-green)

A second Collegiate Cyber Defense Competition range in [Ludus](https://ludus.cloud),
built from the reusable `CCDC-RANGE-PROMPT-TEMPLATE.md` pattern and swapped to a new
technology stack. Range ID **`CCDC2`** (rangeNumber 51 → `10.51.<vlan>.<octet>`),
AD domain **`ccdc.local`** served by a **Samba** Domain Controller (Linux).

> **Key difference from the first build:** the DC is Samba (Linux), so Ludus's
> built-in Windows `domain:` block is **not** used — every host's domain
> provisioning, DNS, and join is handled by the custom `ccdc2_*` roles.

## Services

| VM | IP | OS | Service | Delivery |
|----|----|----|---------|----------|
| `CCDC2-dc01` | 10.51.10.10 | Debian 12 | Samba AD DC + DNS | native |
| `CCDC2-desk01` | 10.51.10.20 | Ubuntu 24.04 desktop | Linux workstation + RustDesk | native |
| `CCDC2-fs01` | 10.51.10.30 | Win Server 2022 | SMB file share, 5 dept folders (AD-joined) | native |
| `CCDC2-mail01` | 10.51.10.40 | Debian 12 | Mail (Postfix/Dovecot) + Roundcube, LDAP→DC | Docker |
| `CCDC2-web01` | 10.51.20.10 | Ubuntu 24.04 | WordPress → central DB | Docker |
| `CCDC2-db01` | 10.51.30.10 | Debian 12 | Central MariaDB (WP/SnipeIT/Mantis DBs) | native |
| `CCDC2-auth01` | 10.51.30.20 | Ubuntu 24.04 | Authentik IdP (governs SSH to SnipeIT) | Docker |
| `CCDC2-snipe01` | 10.51.30.30 | Ubuntu 24.04 | Snipe-IT inventory → central DB | Docker |
| `CCDC2-tick01` | 10.51.30.40 | Debian 12 | MantisBT ticketing → central DB | native |
| `CCDC2-siem01` | 10.51.40.10 | Ubuntu 24.04 | Elastic SIEM (Fleet) | Docker |
| `CCDC2-nas01` | 10.51.40.20 | Debian 12 | TrueNAS-substitute backup (SMB/NFS + restic) | native |

RustDesk (remote support) is installed on the desktop + all Linux servers. Elastic
Agents enroll the desktop + Linux servers to the SIEM (phase 2 — see `docs/DEPLOY.md`).

## Layout
- `ccdc2-range.yml` — the Ludus range config (deployed).
- `roles/` — 12 custom `ccdc2_*` roles (+ `ROLE_CONVENTIONS.md`).
- `docs/` — VMs, network, access URLs, credentials, AD integration, deploy runbook,
  WireGuard access (`docs/WIREGUARD-ACCESS.md`),
  validation, and creating a console-only team user (`docs/TEAM-USER.md`).
- `scripts/` — role install, deploy, TrueNAS template build, elastic agent enrollment.
- `CCDC-RANGE-2-PLAN.md` — the design/plan doc.

Deploy is orchestrated via the **Ludus MCP** (no local `ludus` CLI). See
`docs/DEPLOY.md`. Credentials are committed as role defaults **by design** — keep
this repo private.
