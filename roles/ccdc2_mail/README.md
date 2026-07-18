# ccdc2_mail

Email for the range: **docker-mailserver** (Postfix + Dovecot) + **Roundcube**
webmail, with mailboxes provisioned from and authenticated against the **Samba AD
DC** over LDAP. Adapted from the `jessefmoore/uwb_club` mailserver playbook (moved
off `community.docker` to the range's template-compose convention, and wired to
Samba AD).

## Ports (on 10.51.10.40)
- Webmail (Roundcube): `80`
- SMTP `25`/`587`/`465`, IMAP `143`/`993` (docker-mailserver, self-signed TLS)

## Auth
Users sign in to Roundcube with their **AD** username/email + password. Dovecot
does an LDAP auth-bind against the DC (`10.51.10.10`), matching users by
`sAMAccountName`; mailbox addresses come from each user's `mail` attribute
(`<user>@ccdc.local`, seeded by `ccdc2_samba_dc`). Example login: `jsmith` /
`CCDC2-User-2026!`.

## Verify
```
curl -I http://10.51.10.40/            # Roundcube login page
docker logs ccdc2_mailserver 2>&1 | grep -i ldap | tail
```
Then log into Roundcube as a seeded AD user and send a test message.
