# ccdc2_authentik

Deploys **authentik** (identity provider) on a Linux host via docker compose:
`server` + `worker` + `postgresql` + `redis`, with the **embedded LDAP outpost**
published so the SnipeIT host (`ccdc2-snipe01`) can authenticate **SSH** against
authentik. Pairs with the `ccdc2_authentik_ssh` role that configures SSSD on the
SnipeIT box.

## Ports (on 10.51.30.20)
- `9000` HTTP UI · `9443` HTTPS UI
- `389` LDAP · `636` LDAPS (embedded outpost)

## Credentials
- Admin user **akadmin** / `ccdc2_authentik_bootstrap_password`
  (default `CCDC2-Authentik-2026!`). First login: `http://10.51.30.20:9000/if/flow/initial-setup/`.
- The SnipeIT SSSD search-bind uses `cn=akadmin,ou=users,{{ base_dn }}` with that
  same password (see `ccdc2_authentik_ssh`).

## LDAP outpost — fully automated (`tasks/finalize.yml`)
On deploy, the role calls the Authentik API (bootstrap token) to, idempotently:
1. Create the **LDAP provider** `CCDC2 LDAP Provider` (base `dc=ldap,dc=goauthentik,dc=io`;
   authentik 2025.2 schema: `authorization_flow` + `invalidation_flow`).
2. Create a **dedicated LDAP outpost** object + read its token. (The *embedded*
   outpost serves Proxy providers only — LDAP needs its own outpost.)
3. Run the `ghcr.io/goauthentik/ldap` outpost container (version-matched) publishing
   **389/636**, then wait for the listener.

`ccdc2_authentik_ssh` (on the SnipeIT box) points SSSD at `10.51.30.20:389` and
verifies bind + `getent`. Verified working: `getent passwd akadmin` returns a POSIX
user, so authentik users can SSH into snipe01.

Optional (UI): **Directory → create an LDAP Source** to `10.51.10.10`, bind
`CCDC\svc_ldap`, base `dc=ccdc,dc=local` to also federate the Samba AD users into
authentik.

## Verify
```
curl -sf http://10.51.30.20:9000/-/health/live/ && echo OK
ldapsearch -x -H ldap://10.51.30.20:389 -D 'cn=akadmin,ou=users,dc=ldap,dc=goauthentik,dc=io' -w 'CCDC2-Authentik-2026!' -b 'dc=ldap,dc=goauthentik,dc=io' '(cn=akadmin)'
```
