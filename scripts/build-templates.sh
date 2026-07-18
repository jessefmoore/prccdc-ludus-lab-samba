#!/usr/bin/env bash
# =============================================================================
# build-templates.sh — build the real TrueNAS template CCDC-RANGE-2 substitutes.
#
# The range uses a Debian 12 host (ccdc2_truenas_backup) as a stand-in for the
# TrueNAS backup appliance, because TrueNAS is its own OS with no built Ludus
# template. Build a real TrueNAS SCALE template from ISO, then swap nas01's
# template + role.
# =============================================================================
set -euo pipefail

echo "==> Current templates:"
ludus templates list

cat <<'EOF'

  # ---------------------------------------------------------------------------
  # TrueNAS SCALE (Debian-based appliance) — build from ISO (30-90 min).
  # There is no upstream Ludus packer template for TrueNAS, so add a custom
  # template definition (packer/cloud-init) that boots the TrueNAS SCALE ISO and
  # completes the guided install, then:
  #     ludus templates build -n truenas-scale-x64-template
  #     ludus templates logs -f
  #     ludus templates status
  #
  # Then in ccdc2-range.yml, change nas01:
  #     template: debian-12-x64-server-template   ->  truenas-scale-x64-template
  # remove the ccdc2_truenas_backup role, and configure the appliance with the
  # stevefulme1.truenas Ansible role (dataset/share/replication via the TrueNAS
  # middleware API). Point the other hosts' backups at the real NAS.
  # ---------------------------------------------------------------------------

EOF
echo "Until then, nas01 serves SMB (\\\\10.51.40.20\\backups) + NFS + daily restic."
