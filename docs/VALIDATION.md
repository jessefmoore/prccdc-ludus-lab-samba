# CCDC-RANGE-2 — Validation

## Deploy result
`rangeState: SUCCESS` — all 12 VMs, final PLAY RECAP **failed=0, unreachable=0**
on every host (2026-07-19):

```
CCDC2-dc01    ok=36  failed=0     CCDC2-auth01  ok=56  failed=0
CCDC2-desk01  ok=35  failed=0     CCDC2-snipe01 ok=48  failed=0
CCDC2-fs01    ok=72  failed=0     CCDC2-tick01  ok=57  failed=0
CCDC2-mail01  ok=56  failed=0     CCDC2-siem01  ok=86  failed=0
CCDC2-web01   ok=60  failed=0     CCDC2-nas01   ok=39  failed=0
CCDC2-db01    ok=45  failed=0     router        ok=45  failed=0
```

## Service-level validation (in-VM health checks that gate SUCCESS)
Each role runs its own on-target check; SUCCESS means they passed:
- **Samba AD DC** — `samba-tool domain level show` OK; groups + `svc_ldap` + users seeded.
- **Central MariaDB** — root creds verified; `wordpress`/`snipeit`/`mantisbt` DBs+users created.
- **WordPress** — container up + `wp core install` + HTTP 200 smoke check.
- **SnipeIT** — container up + HTTP warm-up against `/setup`.
- **MantisBT** — Apache/PHP + tarball install + schema created in central DB.
- **Authentik** — stack up + `GET /-/health/live/` returned healthy.
- **Mail** — docker-mailserver + Roundcube up (HTTP wait) + LDAP config to DC.
- **Elastic SIEM** — container reported "up and running" at `https://10.51.40.10:5601`,
  Fleet server created, enrollment token issued (used for agents below).
- **File share** — `Departments` SMB share published; 5 dept folders ACL'd to AD groups.
- **Backup NAS** — SMB + NFS exports + restic repo initialised + daily timer enabled.
- **RustDesk** — installed + service enabled on the desktop and all Linux servers.

## Phase 2 — Elastic agents
Agents enrolled on the 9 Linux hosts (desktop + servers; fs01/Windows and siem01
itself excluded) to Fleet at `https://10.51.40.10:8220`. Confirm in Kibana → Fleet → Agents
(`https://10.51.40.10:5601`, `elastic`/`elasticpassword`).

## Live browsing note (WireGuard)
The Ludus WireGuard config for user `JM` currently does not advertise the
`10.51.0.0/16` subnet to the client peer, so live external probing of CCDC2 from
outside the range isn't available until the server-side WG allowed-IPs include the
new range. This is a Ludus WG/allowed-IPs matter, not a range-build issue — the
services are validated in-VM by the role health checks above. To browse live,
access via the Proxmox console or update the WG peer to route `10.51.0.0/16`.

## Guided finalizes (documented, not auto-forced)
- **Authentik LDAP outpost → SSH-to-SnipeIT**: add the LDAP provider to the
  embedded outpost in the Authentik UI — see `roles/ccdc2_authentik/README.md`.
