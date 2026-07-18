# ccdc2_wordpress

WordPress on Ubuntu 24.04 via Docker for the CCDC2 range, running on
**ccdc2-web01 (10.51.20.10)**. There is **no local database container** —
WordPress connects to the range's **CENTRAL MariaDB** host at
**10.51.30.10** (database `wordpress`, user `wp_user`), which is provisioned
separately by the `ccdc2_centraldb` role. This role only *connects* to it.

Docker and the `docker compose` plugin are assumed to already be installed
(`geerlingguy.docker` runs before this role in the VM's role list).

## What it does

1. Creates the stack directory `/opt/ccdc2/wordpress` (mode `0755`).
2. Downloads `wp-cli.phar` into the stack dir. The official `wordpress`
   image does **not** ship WP-CLI, so the phar is bind-mounted read-only into
   the container as `/usr/local/bin/wp` (simpler/more reliable than trying to
   `curl` it from inside the container).
3. Templates `docker-compose.yml` (single `wordpress:6-php8.3-apache`
   service, `restart: unless-stopped`, port `80:80`, a named volume for
   `/var/www/html` so `wp-content`/uploads/themes/plugins persist across
   recreates) and runs `docker compose up -d` (idempotent — only reported as
   changed when compose actually starts/creates/recreates a container).
4. Waits for the central DB host to accept TCP connections on `3306`, then
   waits for the container's HTTP port, then waits (retry loop) until WP-CLI
   is usable inside the container.
5. Checks `wp core is-installed`; if the site isn't installed yet, runs
   `wp core install` (via `docker compose exec -T wordpress wp ... --allow-root`)
   with the URL/title/admin creds below, `--skip-email`, so the site is
   **live** immediately instead of showing the WordPress setup wizard.
   Idempotent: re-running the role skips the install once it's done.
6. Smoke-checks the site over HTTP (expects `200`).

## Variables (see `defaults/main.yml`)

| Variable | Default | Purpose |
|---|---|---|
| `ccdc2_wordpress_stack_dir` | `/opt/ccdc2/wordpress` | Compose stack directory |
| `ccdc2_wordpress_image` | `wordpress:6-php8.3-apache` | Container image |
| `ccdc2_wordpress_http_port` | `80` | Host port published to container's `80` |
| `ccdc2_wordpress_db_host` | `10.51.30.10` | **Central** MariaDB host (remote, not local) |
| `ccdc2_wordpress_db_port` | `3306` | Central DB port |
| `ccdc2_wordpress_db_name` | `wordpress` | Database name |
| `ccdc2_wordpress_db_user` | `wp_user` | Database user |
| `ccdc2_wordpress_db_password` | `CCDC2-WP-2026!` | Database password (override via role_vars) |
| `ccdc2_wordpress_db_table_prefix` | `wp_` | `WORDPRESS_TABLE_PREFIX` |
| `ccdc2_wordpress_db_wait_retries` / `_delay` | `24` / `5` | Retry loop waiting for the DB/container to be ready (~2 min) |
| `ccdc2_wordpress_site_url` | `http://{{ ansible_host \| default('10.51.20.10') }}` | Site URL used for `wp core install` |
| `ccdc2_wordpress_site_title` | `CCDC2 Corporate` | Site title |
| `ccdc2_wordpress_admin_user` | `wpadmin` | WP admin username |
| `ccdc2_wordpress_admin_password` | `CCDC2-WP-Admin-2026!` | WP admin password (override via role_vars) |
| `ccdc2_wordpress_admin_email` | `wpadmin@ccdc.local` | WP admin email |
| `ccdc2_wordpress_wpcli_url` | wp-cli.phar release URL | Where to download WP-CLI from |

## Credentials

- **WordPress admin**: `wpadmin` / `CCDC2-WP-Admin-2026!` (`wpadmin@ccdc.local`)
- **Database** (central, remote): host `10.51.30.10:3306`, db `wordpress`,
  user `wp_user` / `CCDC2-WP-2026!`

## Verify

```bash
# Site is live (not the install wizard):
curl -I http://10.51.20.10

# Container is up:
docker ps --filter name=ccdc2-wordpress

# WP-CLI confirms the install:
cd /opt/ccdc2/wordpress && docker compose exec -T wordpress wp core is-installed --allow-root --path=/var/www/html && echo INSTALLED

# Log in at http://10.51.20.10/wp-admin/ with the admin creds above.
```

## Troubleshooting

- If `wp core install` fails with a DB connection error, confirm the central
  DB host (`ccdc2_wordpress_db_host`, default `10.51.30.10`) is reachable on
  `3306` from ccdc2-web01 and that the `ccdc2_centraldb` role has already
  provisioned the `wordpress` database/`wp_user` grants.
- Re-running the role is safe: it will not re-install core once
  `wp core is-installed` reports success, and `docker compose up -d` will not
  recreate a healthy, unchanged container.
