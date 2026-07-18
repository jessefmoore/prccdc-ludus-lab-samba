# ccdc2_mantis

Installs **MantisBT** (IT-support / bug ticketing system) natively on Debian
12 — Apache + mod_php + the upstream `mantisbt.org` release tarball. This is
**not** a Docker deployment (the official MantisBT Docker image and the
outdated `NewErr0r/ansible-role-mantis` galaxy role are unreliable) and it
does **not** run a local database — MantisBT connects to the range's
**central MariaDB host** (`ccdc2_centraldb`, `10.51.30.10`), same as
WordPress and SnipeIT on this range.

Target host: `ccdc2-tick01` (`10.51.30.40`).

## What it does

1. Installs `apache2 php libapache2-mod-php php-mysql php-mbstring php-curl
   php-gd php-xml mariadb-client unzip curl` (non-interactive, retried).
2. Downloads the MantisBT release tarball from SourceForge (the GitHub
   mirror only has git tags, no Release tarball assets) to
   `/opt/ccdc2/mantis/`, then extracts it into `/var/www/html/mantis`
   (stripping the top-level `mantisbt-<version>/` directory). Guarded by
   `creates: /var/www/html/mantis/core.php` so re-runs are a no-op.
3. Sets `www-data` ownership on the whole MantisBT tree.
4. Templates `config/config_inc.php` pointing at the **central** MariaDB
   host/database/user (mode `0640`, owner `www-data`), with a fixed (but
   overridable) crypto master salt so the file is reproducible across runs.
5. Enables and starts `apache2` (Debian's default `DocumentRoot` is already
   `/var/www/html`, so no vhost changes are needed — the app is served at
   `http://10.51.30.40/mantis/`).
6. **Idempotently installs the database schema**: it runs the `mysql` CLI
   against the central DB host to check whether `mantis_config_table`
   already exists in the `mantisbt` database. If not, it drives MantisBT's
   own schema installer (`admin/install.php`) with one non-interactive
   `ansible.builtin.uri` POST (`install=2` plus the DB parameters), which
   creates all ~30 `mantis_*` tables and writes the "installation complete"
   state in a single request. It then re-checks the DB and prints a
   `debug` warning (rather than failing the whole play) if the automated
   step didn't take, pointing at the one-time manual fallback below.

## Is the schema install fully automated?

**Yes, in normal conditions** — this was verified end-to-end in a throwaway
Debian 12 + Apache + PHP + MariaDB container while authoring this role: a
single POST to `admin/install.php` with
`install=2&hostname=...&db_type=mysqli&database_name=...&db_username=...&db_password=...&admin_username=...&admin_password=...&path=`
produced "MantisBT was installed successfully" and created all tables
(`mantis_config_table`, `mantis_bug_table`, etc.).

One field is load-bearing and easy to get wrong: **`path=""` must be sent
explicitly.** MantisBT auto-derives `$g_path` from the HTTP request when it
is unset, then tries to *self-fetch* that URL as a sanity check during
install — that outbound self-fetch fails inside a fresh VM/container and
turns into a **hard** failure that aborts the whole install. Explicitly
posting an empty `path` field makes MantisBT take its "empty path is a
security risk" **soft**-warning branch instead, which does not abort
installation. The task in `tasks/main.yml` includes this comment/field; if a
future MantisBT release changes `admin/install.php`'s internals, re-verify
against a scratch container before trusting the automation on the range.

If the automated POST ever doesn't result in `mantis_config_table` existing
(e.g. a MantisBT version bump changed the wizard), the role will not fail
the play — it prints a `debug` warning. Finish manually in a browser:

```
http://10.51.30.40/mantis/admin/install.php
```

`config/config_inc.php` is already correct at that point, so the form will
be pre-filled — just click **"Install/Upgrade Database"**.

## Variables (see `defaults/main.yml`)

| Variable | Default | Purpose |
|---|---|---|
| `ccdc2_mantis_version` | `"2.27.0"` | MantisBT release to install |
| `ccdc2_mantis_download_url` | SourceForge mantis-stable URL for the version above | Tarball source |
| `ccdc2_mantis_download_dir` | `/opt/ccdc2/mantis` | Download staging dir |
| `ccdc2_mantis_webroot` | `/var/www/html/mantis` | Where the app is extracted/served from |
| `ccdc2_mantis_packages` | apache2, php, etc. | apt packages installed |
| `ccdc2_mantis_db_host` | `10.51.30.10` | Central MariaDB host |
| `ccdc2_mantis_db_name` | `mantisbt` | Database name (must match `ccdc2_centraldb`) |
| `ccdc2_mantis_db_user` | `mantis` | Database user (must match `ccdc2_centraldb`) |
| `ccdc2_mantis_db_password` | `CCDC2-Mantis-2026!` | Database password (must match `ccdc2_centraldb`) |
| `ccdc2_mantis_crypto_master_salt` | fixed default string | `$g_crypto_master_salt` (override for a unique value) |
| `ccdc2_mantis_timezone` | `America/Los_Angeles` | `$g_default_timezone` |

The DB host/name/user/password **must match** the `mantisbt` entry in the
`ccdc2_centraldb_databases` list on the `ccdc2_centraldb` role — that role
is what actually creates the database, user, and grants on `10.51.30.10`.
This role only connects to it; it never installs or configures a database
server itself.

## Default admin login

A fresh MantisBT install ships the default administrator account:

- Username: `administrator`
- Password: `root`

**Change this password immediately after first login** — it is a
well-known default and this box is reachable on the range network.

## Security note: the `admin/` directory

MantisBT's own documentation recommends removing or otherwise blocking
access to `/var/www/html/mantis/admin/` after installation, since anyone who
can reach `admin/install.php` could re-run the installer or view PHP/DB
diagnostic info. This role **intentionally leaves it in place** (lab
environment, and the role itself needs to re-run `admin/install.php` on
subsequent playbook runs to stay idempotent). If hardening this box for a
scored event, consider adding a follow-up task/role that denies web access
to `admin/` once you've confirmed the install is healthy.

## Verify

```bash
# Application responds:
curl -I http://10.51.30.40/mantis/login_page.php

# Schema present on the central DB (from the DB host or any host that can
# reach it):
mysql -h 10.51.30.10 -u mantis -p'CCDC2-Mantis-2026!' \
  -e "SHOW TABLES LIKE 'mantis_config_table';" mantisbt
```

Then log in at `http://10.51.30.40/mantis/login_page.php` with
`administrator` / `root` and change the password.
