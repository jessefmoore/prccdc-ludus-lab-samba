# ccdc2_centraldb

Native MariaDB server (Debian 12, **no Docker**) acting as the CCDC2 range's
central database host. Hosts the databases for WordPress, SnipeIT and
MantisBT, which run on other hosts and connect to this server remotely.
Idempotent and safe to re-run.

## What it does

1. **Installs** `mariadb-server` and `mariadb-client` via `ansible.builtin.apt`
   (`DEBIAN_FRONTEND=noninteractive`, retried up to 3 times).
2. **Opens up networking.** Deploys a drop-in,
   `/etc/mysql/mariadb.conf.d/99-ccdc2.cnf`, setting `bind-address = 0.0.0.0`
   and `port = 3306` — overriding Debian's default `127.0.0.1`-only bind in
   `50-server.cnf` (drop-ins are read in lexical order, so `99-` wins).
   Notifies a handler that restarts `mariadb`, flushed immediately so remote
   app hosts can connect as soon as the role finishes.
3. **Enables + starts** the `mariadb` service.
4. **Sets the root password idempotently.** Debian's package ships
   `root@localhost` using passwordless `unix_socket` auth. The role checks
   if that's still the case (`mysql -u root -e 'SELECT 1;'` succeeds with no
   password); if so, it runs a one-time `mysql_secure_installation`-style
   block over the local socket: `ALTER USER 'root'@'localhost' IDENTIFIED BY
   ...`, drops the anonymous user, and drops the `test` database. Once the
   password is set, this check fails on future runs, so the block never
   re-runs. All later `mysql` calls authenticate with an argv-based
   `-u root -p<password>` arg list (no shell quoting issues with special
   characters like `!`).
5. **Provisions databases/users/grants** for every entry in
   `ccdc2_centraldb_databases`: `CREATE DATABASE IF NOT EXISTS ... CHARACTER
   SET utf8mb4 COLLATE utf8mb4_unicode_ci`, `CREATE USER IF NOT EXISTS`,
   `ALTER USER ... IDENTIFIED BY`, `GRANT ALL ... TO ...`, `FLUSH PRIVILEGES`.
   A `SHOW DATABASES LIKE` check gates the `changed` status per database.

No firewall is opened — the Ludus range network is flat/ACCEPT; MariaDB just
needs to listen on `0.0.0.0`.

Does **not** use the `community.mysql` or `community.docker` collections
(not installed in this environment) — only `ansible.builtin.apt/template/
command/service`.

## Variables (see `defaults/main.yml`)

| Variable | Default | Purpose |
|---|---|---|
| `ccdc2_centraldb_packages` | `[mariadb-server, mariadb-client]` | Packages installed |
| `ccdc2_centraldb_bind_address` | `0.0.0.0` | Interface MariaDB listens on |
| `ccdc2_centraldb_port` | `3306` | TCP port |
| `ccdc2_centraldb_root_password` | `CCDC2-DBRoot-2026!` | MariaDB root password |
| `ccdc2_centraldb_databases` | see below | List of DB/user/password/grant_host entries |

Default `ccdc2_centraldb_databases`:

| Database | User | Password | Grant host |
|---|---|---|---|
| `wordpress` | `wp_user` | `CCDC2-WP-2026!` | `%` |
| `snipeit` | `snipeit` | `CCDC2-Snipe-2026!` | `%` |
| `mantisbt` | `mantis` | `CCDC2-Mantis-2026!` | `%` |

Override the whole list (e.g. to add a database, change a password, or
restrict `grant_host` to a specific app-host IP/subnet instead of `%`) via
`role_vars`/`global_role_vars` in Ludus.

## Verify

```bash
# MariaDB is listening on all interfaces, port 3306:
ss -ltnp | grep 3306

# From a remote app host, each application user can reach its database:
mysql -h 10.51.30.10 -u wp_user -p wordpress -e 'SELECT 1;'
mysql -h 10.51.30.10 -u snipeit -p snipeit -e 'SELECT 1;'
mysql -h 10.51.30.10 -u mantis -p mantisbt -e 'SELECT 1;'

# Locally on the DB host, root auth works with the configured password:
mysql -u root -p -e 'SHOW DATABASES;'
```
