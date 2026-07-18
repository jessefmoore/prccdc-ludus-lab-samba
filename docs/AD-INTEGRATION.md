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

## Authentik SSH-to-SnipeIT — the chain
`AD users → (Authentik LDAP source federates them) → Authentik embedded LDAP
outpost (10.51.30.20:389) → snipe01 SSSD/PAM → SSH`.

Authentik is deployed and healthy automatically. The LDAP provider/outpost binding
is a short, version-sensitive UI step (not force-automated to avoid a broken
blueprint). Finalize:
1. Authentik UI → Providers → confirm/create **LDAP Provider** (base `dc=ldap,dc=goauthentik,dc=io`).
2. Outposts → **authentik Embedded Outpost** → add the LDAP provider.
3. (optional) Directory → create an **LDAP Source** to `10.51.10.10` (bind `CCDC\svc_ldap`).
Then `getent passwd <user>` on snipe01 resolves authentik users and SSH works.
The SnipeIT box always keeps its local Ludus login regardless, so nothing is bricked.

## Verify AD itself
```
samba-tool user list                       # on dc01
host -t SRV _ldap._tcp.ccdc.local 10.51.10.10
ldapsearch -x -H ldap://10.51.10.10 -D 'CCDC\svc_ldap' -w 'CCDC2-Svc-2026!' \
  -b 'dc=ccdc,dc=local' '(sAMAccountName=jsmith)'
```
