# CCDC-RANGE-2 — Deploy Runbook

Deployed via the **Ludus MCP** as admin `JM` (no local `ludus` CLI). Range `CCDC2`,
rangeNumber 51.

## Order of operations (already done for the initial build)
1. Install community roles — `geerlingguy.docker`, `badsectorlabs.ludus_elastic_container`,
   `badsectorlabs.ludus_elastic_agent` (MCP `InstallRole`).
2. Install the 12 custom roles — `tar czf <role>.tar.gz -C roles <role>` then MCP
   `InstallRoleTar` (multipart, `file`=absolute tar path, `force`=true). See
   `scripts/install-roles.sh` for the CLI equivalent.
3. `createRange` (rangeID `CCDC2`, rangeNumber 51).
4. `putConfig` (`ccdc2-range.yml`, rangeID `CCDC2`).
5. `deployRange` (rangeID `CCDC2`, tags `all`).

## Monitor
- MCP `listRange {rangeID: CCDC2}` → `rangeState` (DEPLOYING → SUCCESS / ERROR).
- On ERROR: MCP `getLogs {rangeID: CCDC2, tail: 150}`, fix the role, re-tar +
  `InstallRoleTar`, then redeploy (optionally `limit`=`CCDC2-<host>` or `only_roles`).

## Deploy-ordering note (DC first)
Ludus runs roles host-by-host in **IP order**, so `dc01` (10.51.10.10) provisions
Samba AD **before** any host tries to join. If a later host fails, it can abort the
role phase for hosts after it (cascade) — fix the role and redeploy the cut-off
hosts with `limit`.

## Elastic SIEM — PHASE 2 (agent enrollment)
The Elastic agent needs an enrollment token that only exists **after** the SIEM
container is up, so agents are **commented out** in `ccdc2-range.yml` for phase 1.
After the range reaches SUCCESS:

1. Read the token from siem01: `/opt/elastic_container/enrollment_token.txt`
   (SSH to 10.51.40.10, or `getLogs`). 
2. Set it in `ccdc2-range.yml` → `global_role_vars.ludus_elastic_enrollment_token`.
3. Uncomment every `# - badsectorlabs.ludus_elastic_agent   # phase 2` line
   (desk01, mail01, web01, db01, auth01, snipe01, tick01, nas01).
4. `putConfig` + `deployRange` again. Agents enroll to Fleet at `10.51.40.10:8220`.

`scripts/enroll-elastic-agents.sh` documents the exact steps.

## Authentik SSH — finalize (guided)
Authentik deploys fully automatically; wiring its LDAP outpost for SSH-to-SnipeIT
is a short one-time UI step (version-sensitive) — see `roles/ccdc2_authentik/README.md`
and `docs/AD-INTEGRATION.md`.

## Access the range
- WireGuard config: MCP `getWireguardConfig` (AllowedIPs include 10.51.0.0/16).
- SSH creds: MCP `getAnsibleInventory`. **WireGuard drops the first packet** — warm
  a host:port then retry probes.

## Rebuild from scratch
`deleteRange {rangeID: CCDC2, force: true}` → `createRange` (rangeNumber 51) →
`putConfig` → `deployRange`. AD/Samba provisioning is idempotent; a 2nd deploy pass
is safe if any host hit a transient.
