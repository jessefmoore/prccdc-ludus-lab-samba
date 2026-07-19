#!/usr/bin/env bash
# =============================================================================
# enroll-elastic-agents.sh — PHASE 2 of the Elastic SIEM: enroll agents on the
# Linux desktop + servers once the SIEM container (siem01) is up.
#
# badsectorlabs.ludus_elastic_agent AUTO-DISCOVERS the enrollment token and the
# Fleet server URL from what ludus_elastic_container saved on the Ludus host, so
# the agents need NO role_vars. They're only commented out for phase 1 because
# siem01 (VLAN40) deploys AFTER the agent hosts in IP order, so the token isn't
# saved yet on the first pass. Do NOT set the token/URL by hand.
# Usage:  ./enroll-elastic-agents.sh [RANGEID]     (default CCDC2)
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
RANGEID="${1:-CCDC2}"

echo "==> 1. Uncomment the agent role on the monitored Linux hosts:"
echo "      sed -i 's/# - badsectorlabs.ludus_elastic_agent/- badsectorlabs.ludus_elastic_agent/' ccdc2-range.yml"
echo "    (dc01, desk01, mail01, web01, db01, auth01, snipe01, tick01, nas01)"
echo
echo "==> 2. Re-push + redeploy (the agents auto-discover token + Fleet URL):"
echo "      ludus range config set -f ccdc2-range.yml"
echo "      ludus range deploy"
echo
echo "View agents in Kibana -> Fleet -> Agents (https://10.51.40.10:5601,"
echo "elastic / <ludus_elastic_password>, default 'elasticpassword')."
