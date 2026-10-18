# CCDC-RANGE-2 — Deploy Runbook

Originally built via raw Ludus MCP tool calls as admin `JM`. Range `CCDC2`,
rangeNumber 51. This doc is the detailed reference for that call sequence — for a
guided path, see the README's two quick starts instead:
- **[Quick start](../README.md#quick-start-deploy-this-range)** — the local
  `ludus` v2 CLI + this repo's `scripts/*.sh`.
- **[Quick start via Claude Code](../README.md#alternative-deploy-via-the-ludus-mcp-server--claude-code)**
  — the same steps below, but driven conversationally through the official
  [Ludus MCP server](https://docs.ludus.cloud/docs/using-ludus/mcp)
  (`@badsectorlabs/ludus-mcp`) instead of calling the tools by hand.

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
`badsectorlabs.ludus_elastic_agent` **auto-discovers** the enrollment token *and*
the Fleet server URL from what `ludus_elastic_container` saved on the Ludus host —
so the agents need **no** `role_vars` (do NOT set the token/URL manually; a bad
manual URL causes an `elastic-agent` "cannot contain colon" error). The agents are
only commented out because siem01 (VLAN40) deploys **after** the agent hosts in IP
order, so the token isn't saved yet on the first pass.

After the range reaches SUCCESS (container up + token saved):
1. Uncomment every `# - badsectorlabs.ludus_elastic_agent` line
   (dc01, desk01, mail01, web01, db01, auth01, snipe01, tick01, nas01).
2. `putConfig` + `deployRange` again — the agents auto-enroll to Fleet.

That's it — no token to copy. `scripts/enroll-elastic-agents.sh` documents it.

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
