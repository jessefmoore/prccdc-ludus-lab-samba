#!/usr/bin/env bash
# =============================================================================
# deploy.sh — push the CCDC-RANGE-2 config and deploy it.
# CLI equivalent of the MCP putConfig / deployRange calls.
# Usage:  ./deploy.sh [RANGEID] [TEAMID]     (RANGEID default CCDC2)
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
RANGEID="${1:-CCDC2}"
TEAMID="${2:-}"
USER_ARG=""; [[ -n "$TEAMID" ]] && USER_ARG="--user $TEAMID"
RANGE_ARG="--range $RANGEID"

echo "==> Setting range config for $RANGEID"
ludus range config set -f ccdc2-range.yml $RANGE_ARG $USER_ARG

echo "==> Deploying $RANGEID (all VMs + Samba AD; ~1-3 hours)"
ludus range deploy $RANGE_ARG $USER_ARG

echo "==> Follow:  ludus range logs -f $RANGE_ARG $USER_ARG   |   status: ludus range list $RANGE_ARG $USER_ARG"

# --- Notes -------------------------------------------------------------------
# * Ludus runs roles in IP order, so dc01 (Samba AD) provisions first. If a host
#   fails it can cascade to later hosts — fix the role and redeploy cut-off hosts:
#     ludus range deploy $RANGE_ARG $USER_ARG --limit CCDC2-<host>
# * Samba/AD provisioning is idempotent; a 2nd deploy pass is safe on a transient.
# * Elastic agents are PHASE 2 — see scripts/enroll-elastic-agents.sh.
