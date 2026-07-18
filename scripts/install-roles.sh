#!/usr/bin/env bash
# =============================================================================
# install-roles.sh — install every role CCDC-RANGE-2 needs into Ludus.
# CLI equivalent of the MCP InstallRole / InstallRoleTar calls used to build the
# range. Run on a machine with the `ludus` CLI configured for the deploying user.
# Idempotent.  Usage: ./install-roles.sh [--user TEAMID]
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
USER_ARG=""
[[ "${1:-}" == "--user" ]] && USER_ARG="--user ${2:?user id required}"

echo "==> Community roles from Ansible Galaxy"
ludus ansible role add geerlingguy.docker                         $USER_ARG || true
ludus ansible role add badsectorlabs.ludus_elastic_container      $USER_ARG || true
ludus ansible role add badsectorlabs.ludus_elastic_agent          $USER_ARG || true

echo "==> Custom ccdc2_* roles from local directories"
for role in \
    ccdc2_samba_dc \
    ccdc2_linux_domain_join \
    ccdc2_centraldb \
    ccdc2_wordpress \
    ccdc2_snipeit \
    ccdc2_mantis \
    ccdc2_authentik \
    ccdc2_authentik_ssh \
    ccdc2_mail \
    ccdc2_fileshare \
    ccdc2_truenas_backup \
    ccdc2_rustdesk ; do
  echo "    - $role"
  ludus ansible role add -d "roles/${role}" $USER_ARG --force
done

echo "==> Done. Verify with:  ludus ansible role list $USER_ARG"
