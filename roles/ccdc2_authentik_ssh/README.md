# ccdc2_authentik_ssh

Points a host's SSH authentication (SSSD → PAM/NSS) at the **authentik embedded
LDAP outpost** (`ccdc2_authentik` on `ccdc2-auth01`). Applied on the SnipeIT host
so "Authentik governs SSH to SnipeIT."

Tolerant by design: if the outpost isn't finalized, SSSD runs offline and the
local Ludus user still logs in, so a deploy never fails here. Once the outpost is
wired (see `ccdc2_authentik` README finalize steps), authentik users can SSH in.

Vars: `ccdc2_authentik_ssh_ldap_uri` (ldap://10.51.30.20:389),
`_base_dn`, `_bind_dn` (akadmin), `_bind_password`.

Verify (after outpost finalize): `getent passwd <authentik-user>` and
`ssh <authentik-user>@10.51.30.30`.
