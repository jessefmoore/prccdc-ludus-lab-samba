# CCDC-RANGE-2 — Build Plan

Filled-in from `CCDC-RANGE-PROMPT-TEMPLATE.md`, swapped to the CCDC-RANGE-2
technology stack. Ludus admin user `JM`. Project dir
`/home/kali/grayhats/prccdc-ludus-lab-2`. Interface: Ludus MCP server.

- **Range ID:** `CCDC2`   **rangeNumber:** `51`  → IPs `10.51.<vlan>.<octet>`
- **Domain:** `ccdc.local` (NetBIOS `CCDC`) — provided by a **Samba AD DC** (Linux),
  which is also DNS for every host.
- Old `CCDC` range (rangeNumber 50) **deleted** to free CPU/RAM/disk. ✅

> **Architecture change vs. the old range:** the DC is **Samba (Linux)**, not
> Windows. Ludus's built-in `domain:` block only provisions a *Windows* DC, so
> **no VM uses `domain:`** here — all domain/DNS/join wiring is done by custom
> roles (Samba provision, realmd/sssd join, Windows offline/`Add-Computer` join).

---

## Requirement → OS / Delivery mapping

| # | Requirement | VM | OS (template) | Delivery | Role |
|---|-------------|----|---------------|----------|------|
| 1 | Samba Domain Controller | `ccdc2-dc01` | Debian 12 server | **Native** (`samba-ad-dc`) | `ccdc2_samba_dc` |
| 2 | Linux Desktop | `ccdc2-desk01` | Ubuntu 24.04 **desktop** | Native + domain-join + RustDesk | `ccdc2_linux_domain_join`, rustdesk |
| 3 | Authentik → SSH auth for SnipeIT | `ccdc2-auth01` | Ubuntu 24.04 server | **Docker** (compose: server/worker/postgres/redis + LDAP outpost) | `ccdc2_authentik` |
| 4 | WordPress website | `ccdc2-web01` | Ubuntu 24.04 server | **Docker** (wordpress) → central DB | `ccdc2_wordpress` |
| 5 | Central Database (holds WP DB) | `ccdc2-db01` | Debian 12 server | **Native MariaDB** (WP + SnipeIT + Mantis DBs) | `ccdc2_centraldb` |
| 6 | SnipeIT inventory | `ccdc2-snipe01` | Ubuntu 24.04 server | **Docker** (`snipe/snipe-it`) → central DB; SSH gated by Authentik; RustDesk | `ccdc2_snipeit` |
| 7 | MantisBT ticketing | `ccdc2-tick01` | Debian 12 server | **Docker** (mantisbt) → central DB; RustDesk | `ccdc2_mantis` |
| 8 | Windows central file share | `ccdc2-fs01` | Windows Server 2022 | Native SMB, 5 dept shares, joined to Samba AD | `ccdc2_fileshare` |
| 9 | TrueNAS backup | `ccdc2-nas01` | **Debian 12 substitute** → real TrueNAS SCALE via build script | Native SMB/NFS + `restic`/`rsync` pulls | `ccdc2_truenas_backup` |
| 10 | Elastic SIEM | `ccdc2-siem01` | Ubuntu 24.04 server | **Docker** (`badsectorlabs.ludus_elastic_container`) | community role |
| 11 | Email (Roundcube) → Samba DC | `ccdc2-mail01` | Debian 12 server | **Native** Postfix/Dovecot/Roundcube, LDAP auth to DC | `ccdc2_mail` |

**RustDesk** (support): installed on the Linux desktop **and every Linux server**
via a Ludus/community rustdesk role (self-hosted relay optional; direct-LAN by default).

**Elastic Agent** (`badsectorlabs.ludus_elastic_agent`): enrolled on the Linux
desktop + all Linux servers, reporting to `ccdc2-siem01`.

---

## Topology (4 VLANs behind a Ludus native Debian router)

**VLAN 10 — Corporate**
- `ccdc2-dc01`  10.51.10.10  — Samba AD DC + DNS (Debian 12)
- `ccdc2-desk01` 10.51.10.20 — Linux Desktop (Ubuntu 24.04 desktop) + RustDesk
- `ccdc2-fs01`  10.51.10.30  — Windows Server 2022 file share (5 dept folders)
- `ccdc2-mail01` 10.51.10.40 — Mail (Postfix/Dovecot/Roundcube)

**VLAN 20 — DMZ**
- `ccdc2-web01` 10.51.20.10  — WordPress (Docker)

**VLAN 30 — Internal services**
- `ccdc2-db01`   10.51.30.10 — Central MariaDB
- `ccdc2-auth01` 10.51.30.20 — Authentik IdP (Docker)
- `ccdc2-snipe01` 10.51.30.30 — SnipeIT (Docker)
- `ccdc2-tick01` 10.51.30.40 — MantisBT (Docker)

**VLAN 40 — Security / Backup**
- `ccdc2-siem01` 10.51.40.10 — Elastic SIEM (Docker)
- `ccdc2-nas01`  10.51.40.20 — TrueNAS backup (Debian substitute)

Router `10.51.10.254`. Network flat/ACCEPT during build (hardening ruleset documented for later).

---

## Template strategy

Everything the requirements need is **already built** on the Ludus server, so the
only substitution is TrueNAS:

- `debian-12-x64-server-template` ✅ (DC, DB, Mantis, mail, NAS-substitute)
- `ubuntu-24.04-x64-server-template` ✅ (Authentik, WordPress, SnipeIT, SIEM)
- `ubuntu-24.04-x64-desktop-template` ✅ (Linux desktop)
- `win2022-server-x64-template` ✅ (file share)
- **TrueNAS** → **substitute** `debian-12` acting as an SMB/NFS backup target.
  `scripts/build-templates.sh` will build a real TrueNAS SCALE template from ISO;
  the `stevefulme1.truenas` role then configures it (needs real TrueNAS middleware/API).

---

## Roles to build / source

Custom (under `roles/`, reusing patterns from the old build where possible):
`ccdc2_samba_dc`, `ccdc2_linux_domain_join` (adapt old realmd/sssd role — realmd
joins Samba AD the same way), `ccdc2_authentik`, `ccdc2_wordpress`,
`ccdc2_centraldb`, `ccdc2_snipeit`, `ccdc2_mantis`, `ccdc2_fileshare` (Windows),
`ccdc2_truenas_backup`, `ccdc2_mail`.

Community / ready-made:
- `badsectorlabs.ludus_elastic_container` + `badsectorlabs.ludus_elastic_agent`
- `geerlingguy.docker` (Docker hosts)
- RustDesk role (verify exact galaxy name at build; author a thin one if none)
- optional: a Samba-AD-DC galaxy role instead of hand-rolled `ccdc2_samba_dc`

Sources to adapt at build time (as you provided):
- Authentik: docs.goauthentik.io docker-compose
- SnipeIT: `snipe/snipe-it` Docker image (recommended) or GR360RY/snipeit-ansible (needs fixing)
- MantisBT: mantisbt.org or NewErr0r/ansible-role-mantis (needs updating)
- TrueNAS: `stevefulme1.truenas`
- Mail: jessefmoore/uwb_club `ansible/playbooks/mailserver.yml`

---

## Rough resource budget (~26 vCPU / ~54 GB RAM — comparable to old range)

router 2/2 · dc01 2/4 · desk01 2/4 · fs01 2/6 · mail01 2/3 · web01 2/4 ·
db01 2/6 · auth01 2/6 · snipe01 2/4 · tick01 2/3 · siem01 4/8 · nas01 2/4
