# ccdc2_samba_dc

Provisions a **Samba Active Directory Domain Controller** for `ccdc.local` on
Debian/Ubuntu using the internal DNS backend, then seeds groups and users.

## What it does
1. Installs Samba + Kerberos, masks the standalone `smbd`/`nmbd`/`winbind`
   (the unified `samba-ad-dc` service owns them).
2. `samba-tool domain provision` (once) → realm `CCDC.LOCAL`, NetBIOS `CCDC`,
   DNS forwarder to the internet.
3. Installs the generated `krb5.conf`, points the host's own resolver at the
   local Samba DNS (disables the systemd-resolved stub so :53 is free).
4. Starts `samba-ad-dc`, relaxes the lab password policy.
5. Seeds department groups (HR/Finance/IT/Sales/Engineering), an `svc_ldap`
   bind account, a plain `ccdcuser`, and one employee per department with a
   `mail` attribute.

## Provides
- **AD DNS** on port 53 (the range's DNS server — point every other VM here).
- **LDAP** on 389/636, **Kerberos** on 88, **SMB** on 445.
- LDAP base DN `dc=ccdc,dc=local`; users live in `cn=Users,dc=ccdc,dc=local`.
- Bind account `cn=svc_ldap,cn=Users,dc=ccdc,dc=local` (pw = service password).

## Key vars (see defaults/main.yml)
`ccdc2_samba_dc_dns_domain` (ccdc.local), `_realm`, `_netbios_domain`,
`_admin_password`, `_service_password`, `_user_password`, `_dns_forwarder`,
`_departments`, `_users`.

## Verify
```
samba-tool domain level show
host -t SRV _ldap._tcp.ccdc.local 127.0.0.1
samba-tool user list
ldapsearch -x -H ldap://10.51.10.10 -D 'CCDC\svc_ldap' -w 'CCDC2-Svc-2026!' -b 'dc=ccdc,dc=local' '(sAMAccountName=jsmith)'
```
