# ccdc2_snipeit

Deploys **Snipe-IT** asset/inventory management on Ubuntu 24.04 using the
official `snipe/snipe-it` Docker image via `docker compose`, connected to the
CCDC2 range's **central MariaDB** (remote host, database `snipeit`) instead of
a local database. Target host: `ccdc2-snipe01` (`10.51.30.30`).

## What it does

1. Creates the stack directory `/opt/ccdc2/snipeit` (mode `0755`).
2. Templates `docker-compose.yml` for the `snipe/snipe-it:latest` container:
   - Publishes port `80` (container serves the Snipe-IT UI on `80`).
   - Sets `APP_ENV=production`, `APP_DEBUG=false`, `APP_KEY`, `APP_URL`,
     `APP_TIMEZONE`.
   - Points at the **central** MariaDB (`ccdc2_snipeit_db_host`, default
     `10.51.30.10`) using **both** env-var styles Snipe-IT has supported
     across versions: legacy `MYSQL_PORT_3306_TCP_ADDR` /
     `MYSQL_PORT_3306_TCP_PORT` / `MYSQL_DATABASE` / `MYSQL_USER` /
     `MYSQL_PASSWORD`, and current `DB_HOST` / `DB_PORT` / `DB_DATABASE` /
     `DB_USERNAME` / `DB_PASSWORD`.
   - Dummy `MAIL_*` settings (no real mail relay required in the lab).
   - `restart: unless-stopped` and a named volume (`ccdc2_snipeit_data` →
     `/var/lib/snipeit`) for persistent app storage/uploads.
3. Runs `docker compose pull` then `docker compose up -d` (chdir'd to the
   stack dir). Both are idempotent/safe to re-run — Docker and the `docker
   compose` plugin are assumed already installed (`geerlingguy.docker` runs
   earlier in the play; this role does not install Docker itself).
4. **Does not create the database.** A separate role (`ccdc2_centraldb`) on
   the DB host (`10.51.30.10`) creates the `snipeit` database and `snipeit`
   user/grants. This role only supplies connection details so the Snipe-IT
   container can reach it. On first boot, the official image's entrypoint
   runs Laravel DB migrations against that central DB automatically.
5. **Waits for warm-up.** Polls `curl -s -o /dev/null -w "%{http_code}"
   http://localhost/setup` (retries/delay tunable via
   `ccdc2_snipeit_wait_retries` / `ccdc2_snipeit_wait_delay`) until any HTTP
   status code comes back, so the play doesn't race the container while it's
   still running migrations. `failed_when: false` — a slow warm-up is logged,
   not fatal.

## SSH access

SSH login to this host is governed separately by Authentik/AD (realm join /
SSSD); it is not this role's concern.

## Variables (see `defaults/main.yml`)

| Variable | Default | Purpose |
|---|---|---|
| `ccdc2_snipeit_stack_dir` | `/opt/ccdc2/snipeit` | Compose stack directory |
| `ccdc2_snipeit_image` | `snipe/snipe-it:latest` | Container image |
| `ccdc2_snipeit_http_port` | `80` | Host port published for the web UI |
| `ccdc2_snipeit_app_url` | `http://10.51.30.30` | `APP_URL` (asset/QR links) |
| `ccdc2_snipeit_app_key` | `base64:2hg8p8V2VqO6oQ0m6E6Yl0m2rD3hQ2yZ8kNfV1cJ4A=` | Laravel `APP_KEY`. Valid as-is; regenerate your own with `docker run --rm snipe/snipe-it php artisan key:generate --show` and override via role_vars if you want a unique key per deployment |
| `ccdc2_snipeit_timezone` | `America/Los_Angeles` | `APP_TIMEZONE` |
| `ccdc2_snipeit_db_host` | `10.51.30.10` | Central MariaDB host |
| `ccdc2_snipeit_db_port` | `3306` | Central MariaDB port |
| `ccdc2_snipeit_db_database` | `snipeit` | Database name (created by `ccdc2_centraldb`) |
| `ccdc2_snipeit_db_username` | `snipeit` | DB user (created by `ccdc2_centraldb`) |
| `ccdc2_snipeit_db_password` | `CCDC2-Snipe-2026!` | DB password (must match `ccdc2_centraldb`) |
| `ccdc2_snipeit_mail_*` | dummy values | `MAIL_*` env vars (no real relay in the lab) |
| `ccdc2_snipeit_wait_retries` | `30` | Warm-up poll attempts |
| `ccdc2_snipeit_wait_delay` | `5` | Seconds between warm-up polls |

## First login

Browse to `http://10.51.30.30` — Snipe-IT's built-in pre-flight setup wizard
runs on first load (base requirements check → DB connectivity check, which
should already pass since the central DB/user were pre-created → create the
first admin user and org settings). No admin credentials are seeded by this
role; the first account you create through the wizard becomes the initial
admin.

## Verify

```bash
curl -I http://10.51.30.30
```

A `200`/`302` response means the Snipe-IT web UI is up. You can also check
container health directly on the host:

```bash
cd /opt/ccdc2/snipeit
docker compose ps
docker compose logs -f snipeit
```
