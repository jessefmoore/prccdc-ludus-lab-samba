# CCDC-RANGE-2 — VMs & Template Substitutions

IP scheme `10.51.<vlan>.<octet>` (rangeNumber 51). Router at `10.51.10.254`.

| VM | VLAN.octet | Template (built) | vCPU | RAM (min) | Roles |
|----|-----------|------------------|------|-----------|-------|
| dc01 | 10.10 | debian-12-x64-server | 2 | 4 (2) | ccdc2_samba_dc |
| desk01 | 10.20 | ubuntu-24.04-x64-desktop | 2 | 4 (2) | ccdc2_linux_domain_join, ccdc2_rustdesk |
| fs01 | 10.30 | win2022-server-x64 | 2 | 6 (3) | ccdc2_fileshare |
| mail01 | 10.40 | debian-12-x64-server | 2 | 4 (2) | domain_join, geerlingguy.docker, ccdc2_mail, rustdesk |
| web01 | 20.10 | ubuntu-24.04-x64-server | 2 | 4 (2) | domain_join, docker, ccdc2_wordpress, rustdesk |
| db01 | 30.10 | debian-12-x64-server | 2 | 6 (3) | domain_join, ccdc2_centraldb, rustdesk |
| auth01 | 30.20 | ubuntu-24.04-x64-server | 2 | 6 (3) | domain_join, docker, ccdc2_authentik, rustdesk |
| snipe01 | 30.30 | ubuntu-24.04-x64-server | 2 | 4 (2) | docker, ccdc2_snipeit, ccdc2_authentik_ssh, rustdesk |
| tick01 | 30.40 | debian-12-x64-server | 2 | 4 (2) | domain_join, ccdc2_mantis, rustdesk |
| siem01 | 40.10 | ubuntu-24.04-x64-server | 4 | 8 (4) | docker, ludus_elastic_container, rustdesk |
| nas01 | 40.20 | debian-12-x64-server | 2 | 4 (2) | ccdc2_truenas_backup, rustdesk |

Totals ≈ 24 vCPU / 54 GB RAM (+ router 2/2).

## Template substitutions
Only **one** substitution — everything else runs on its real target OS because the
templates are already built on the Ludus server:

| Requested | Used | Why |
|-----------|------|-----|
| TrueNAS (appliance OS) | debian-12-x64-server acting as SMB/NFS + restic backup target | No TrueNAS template built; ISO build is slow/heavy. Build a real TrueNAS SCALE template with `scripts/build-templates.sh`, then configure it with `stevefulme1.truenas`. |

The Samba DC is **not** a substitution — it is the requested technology, running on
Debian 12. If a Windows DC is ever wanted instead, that is a different design.
