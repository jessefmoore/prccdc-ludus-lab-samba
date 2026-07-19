# ccdc2_scoring

Deploys the **Quotient** scoring engine ([dbaseqp/Quotient](https://github.com/dbaseqp/Quotient))
via docker compose on `ccdc2-score01` and configures it to score the CCDC2 range.

## Scoreboard
- Web UI: **http://10.51.50.10/** (server on port 80)
- Admin: `admin` / `CCDC2-Score-Admin-2026!` · Team: `blue1` / `CCDC2-Score-Blue1-2026!`
- Starts **paused** (`StartPaused=true`) — log in as admin and press start.
- Stack: `server` + `runner` ×5 + PostgreSQL + Redis (the optional `divisor`
  IP-rotator is skipped). Config at `/opt/ccdc2/quotient/config/event.conf`.

## Scored services (18 — well over the required 10)
| Box | Checks |
|-----|--------|
| dc01 | ping, **DNS** (A `ccdc2-dc01.ccdc.local`), **LDAP** (bind Administrator) |
| desk01 | **SSH** (AD `jsmith`, `hostname` contains `desk01`) |
| fs01 | **RDP** (3389), **SMB** (share `Departments`, file `HR/README-HR.txt`) |
| mail01 | **Web** Roundcube (text `roundcube`), **SMTP**, **IMAP** |
| web01 | **Web** WordPress (text `wp-content/includes`), **SSH** |
| db01 | **TCP** 3306, **SQL** MySQL (`SELECT 1` on `wordpress`) |
| auth01 | **Web** Authentik health (`/-/health/live/` 204), **TCP** LDAP outpost 389 |
| snipe01 | **Web** SnipeIT (text `snipe-it`), **SSH** via Authentik (`akadmin`) |
| tick01 | **Web** MantisBT (text `mantis`) |
| siem01 | **TCP** Kibana 5601 |
| nas01 | **TCP** SMB 445, **TCP** NFS 2049 |

Covers the requested **http, ssh, rdp, website-text** plus DNS, LDAP, SMB, SQL,
SMTP, IMAP, TCP. Checks are editable live in the admin UI, or via `event.conf`.

## Credlists (`config/credlists/`)
`linux` (`jsmith`), `authentik` (`akadmin`), `windows` (`Administrator`),
`db` (`wp_user`) — all overridable via role_vars.

## Verify
```
curl -I http://10.51.50.10/
docker compose -f /opt/ccdc2/quotient/docker-compose.yml ps
```
Then open the UI, log in as admin, unpause, and watch the checks turn green.
