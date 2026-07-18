# ccdc2_truenas_backup

**TrueNAS substitute.** A Debian host that behaves like the range's backup
appliance: it exports a share over **SMB** and **NFS** for other machines to back
up into, and snapshots everything it receives into a local **restic** repository
on a daily timer.

Real TrueNAS SCALE is an appliance OS with no built Ludus template; build one
from ISO via `scripts/build-templates.sh`, then configure it with the
`stevefulme1.truenas` Ansible role. This role stands in until then.

## Provides (on 10.51.40.20)
- SMB share `\\10.51.40.20\backups` (guest-writable, lab) with per-host subdirs.
- NFS export `10.51.40.20:/srv/backups` to `10.51.0.0/16`.
- restic repo at `/srv/restic-repo` (password in `/etc/ccdc2-restic.pass`),
  snapshotted daily at 02:30 by `ccdc2-backup.timer`.

## Verify
```
smbclient -N -L //10.51.40.20
showmount -e 10.51.40.20
systemctl list-timers ccdc2-backup.timer
RESTIC_PASSWORD_FILE=/etc/ccdc2-restic.pass restic -r /srv/restic-repo snapshots
```
Run a backup on demand: `systemctl start ccdc2-backup.service`.
