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

## What is automated vs. manual (finalize)
Automated: full stack up + healthy; a starter **LDAP provider + application**
blueprint (`blueprints/ccdc2/ccdc2-ldap.yaml`) applied best-effort on boot.

Manual finalize (one-time, in the UI — authentik LDAP provider/outpost wiring is
version-sensitive so it is not force-automated):
1. **Applications → Providers**: confirm *CCDC2 LDAP Provider* exists (or create
   an LDAP Provider, base DN `dc=ldap,dc=goauthentik,dc=io`).
2. **Applications → Outposts → authentik Embedded Outpost → Edit**: add the LDAP
   provider so the outpost answers on 389/636.
3. (Optional) **Directory → Federation & Social login → Create → LDAP Source**:
   host `10.51.10.10`, bind `CCDC\svc_ldap`, base `dc=ccdc,dc=local` to import
   the Samba AD users.

## Verify
```
curl -sf http://10.51.30.20:9000/-/health/live/ && echo OK
ldapsearch -x -H ldap://10.51.30.20:389 -D 'cn=akadmin,ou=users,dc=ldap,dc=goauthentik,dc=io' -w 'CCDC2-Authentik-2026!' -b 'dc=ldap,dc=goauthentik,dc=io' '(cn=akadmin)'
```
