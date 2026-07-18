#!/usr/bin/env bash
# =============================================================================
# enroll-elastic-agents.sh — PHASE 2 of the Elastic SIEM: enroll agents on the
# Linux desktop + servers once the SIEM container (siem01) is up.
#
# The Fleet enrollment token only exists AFTER the container deploys, so the
# agent role is commented out in ccdc2-range.yml for phase 1. This wires it up.
# Usage:  ./enroll-elastic-agents.sh [RANGEID]     (default CCDC2)
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
RANGEID="${1:-CCDC2}"

echo "==> 1. Grab the Fleet enrollment token from siem01 (10.51.40.10)"
echo "    ssh into siem01 (via WireGuard) and read:"
echo "      sudo cat /opt/elastic_container/enrollment_token.txt"
echo
echo "==> 2. Put the token into ccdc2-range.yml under global_role_vars:"
echo "      ludus_elastic_enrollment_token: \"<TOKEN>\""
echo
echo "==> 3. Uncomment the agent role on the monitored hosts:"
echo "      sed -i 's/# - badsectorlabs.ludus_elastic_agent.*/- badsectorlabs.ludus_elastic_agent/' ccdc2-range.yml"
echo "    (desk01, mail01, web01, db01, auth01, snipe01, tick01, nas01)"
echo
echo "==> 4. Re-push + redeploy:"
echo "      ludus range config set -f ccdc2-range.yml"
echo "      ludus range deploy"
echo
echo "Agents enroll to Fleet at 10.51.40.10:8220; view them in Kibana ->"
echo "Fleet -> Agents (https://10.51.40.10:5601, elastic/elasticpassword)."
