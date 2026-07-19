# CCDC-RANGE-2 — Directory & Identity Integration

The identity backbone is a **Samba Active Directory DC** (`ccdc.local`,
`10.51.10.10`) providing Kerberos, LDAP, and DNS for the whole range.

## LDAP facts
- Base DN: `dc=ccdc,dc=local`; users/groups in `cn=Users,dc=ccdc,dc=local`.
- Bind account: `CN=svc_ldap,CN=Users,dc=ccdc,dc=local` / `CCDC2-Svc-2026!`.
- Users have `sAMAccountName`, `mail` (`<user>@ccdc.local`), and department group
  membership (HR/Finance/IT/Sales/Engineering).

## Who integrates, and how
| Consumer | Mechanism |
|----------|-----------|
| Linux servers + desktop | `realmd`/`sssd`/`adcli` domain join (`ccdc2_linux_domain_join`) → AD users SSH in; `Domain Admins` get sudo |
| Windows file share (`fs01`) | `microsoft.ad.membership` join → department shares ACL'd to `CCDC\<Dept>` groups |
| Mail (`mail01`) | docker-mailserver LDAP: Dovecot auth-binds users vs AD; mailboxes from `mail` attribute |
| Authentik (`auth01`) | (finalize) LDAP **source** federates AD users; its **outpost** re-serves LDAP for SSH |
| SnipeIT SSH (`snipe01`) | `sssd` → Authentik LDAP outpost (`ccdc2_authentik_ssh`) — "Authentik governs SSH" |

## Authentik SSH-to-SnipeIT — the chain (fully automated + verified)
`Authentik users → Authentik LDAP provider → dedicated LDAP outpost container
(10.51.30.20:389) → snipe01 SSSD/PAM → SSH`.

`ccdc2_authentik`'s `finalize.yml` does this automatically via the Authentik API
(bootstrap token), idempotently:
1. Creates the **LDAP provider** `CCDC2 LDAP Provider` (base `dc=ldap,dc=goauthentik,dc=io`;
   authentik 2025.2 schema `authorization_flow` + `invalidation_flow`).
2. Creates a **dedicated LDAP outpost** object + fetches its token. (The *embedded*
   outpost only serves Proxy providers — LDAP needs its own outpost.)
3. Runs the `ghcr.io/goauthentik/ldap` outpost container publishing **389/636**.

`ccdc2_authentik_ssh` on snipe01 then points SSSD at the outpost and verifies.
**Confirmed working:** bind OK + `getent passwd akadmin` →
`akadmin:*:2004:2004:akadmin:/home/akadmin:/bin/bash`. So authentik users can
`ssh <user>@10.51.30.30`. snipe01 also keeps its local Ludus login, so nothing is bricked.

Optional: add an **LDAP Source** to the Samba DC (`10.51.10.10`, bind `CCDC\svc_ldap`)
in the Authentik UI to federate the AD users into authentik as well.

## Verify AD itself
```
samba-tool user list                       # on dc01
host -t SRV _ldap._tcp.ccdc.local 10.51.10.10
ldapsearch -x -H ldap://10.51.10.10 -D 'CCDC\svc_ldap' -w 'CCDC2-Svc-2026!' \
  -b 'dc=ccdc,dc=local' '(sAMAccountName=jsmith)'
```
