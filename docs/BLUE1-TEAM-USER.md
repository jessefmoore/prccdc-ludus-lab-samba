# Create the `BLUE1` Team User for CCDC2

Concrete, copy-paste steps to give **PRCCDC Blue Team 1** console-only access to
the `CCDC2` range. Run as a Ludus **admin** (e.g. `JM`). For the general concept
and the can/cannot details, see [`TEAM-USER.md`](TEAM-USER.md).

| | Value |
|---|---|
| User ID | `BLUE1` |
| Display name | `PRCCDC Blue Team 1` |
| Email | `blue1@ccdc.local` |
| Range to assign | `CCDC2` (rangeNumber 51) |
| Access | Proxmox **console-only**, scoped to the `CCDC2` pool |

> **Heads-up:** a `BLUE1` user may already exist from the first build. If so,
> **skip step 1** (you'll get "user already exists") and go straight to step 2 to
> assign `CCDC2`. Check first with `ludus user list` / API `listAllUsers`.

---

## Option A — Ludus CLI

```bash
# 1. Create the NON-admin team user (skip if BLUE1 already exists)
ludus user add --name "PRCCDC Blue Team 1" --userid BLUE1     # NO --admin

# 2. Assign the CCDC2 range -> grants scoped Proxmox console access
ludus range assign --user BLUE1 --range CCDC2

# 3. Fetch the Proxmox login to hand to the team
ludus user creds get --user BLUE1

# 4. Verify BLUE1 now has access to CCDC2
ludus range list --user BLUE1
```

## Option B — Ludus MCP / REST API

```jsonc
// 1. addUser  (POST /user)   — isAdmin MUST be false; email required
{ "name": "PRCCDC Blue Team 1", "userID": "BLUE1",
  "isAdmin": false, "email": "blue1@ccdc.local",
  "password": "CCDC2-Blue1-2026!" }     // optional; omit to auto-generate

// 2. assignRangeToUser  (POST /ranges/assign/BLUE1/CCDC2)   — path params, no body

// 3. getCredentials  (GET /user/credentials?userID=BLUE1)
//    -> { proxmoxUsername, proxmoxPassword, proxmoxRealm: "pam", ludusEmail }

// 4. listRangeUsers  (GET /ranges/CCDC2/users)   — confirm BLUE1 is listed
```

---

## How Blue Team 1 logs in
1. Browse to **`https://192.168.0.193:8006`** (Proxmox).
2. **Realm:** `Linux PAM (pam)`. **Username/Password:** the `proxmoxUsername` /
   `proxmoxPassword` from step 3 (username is typically `blue1` / `prccdc-blue-team-1`).
3. In the left tree they see **only the `CCDC2` pool** → pick a VM → **Console**
   (noVNC) to drive it. They can also power on/off/reset their own VMs.

They **cannot** see other ranges, build templates, get a host shell, or admin the
server. Console-only ≠ network access — grant WireGuard separately
(`getWireguardConfig --user BLUE1`) only if you want off-console SSH/RDP.

---

## Undo / rotate
```bash
# Revoke CCDC2 from BLUE1 (keep the user)
ludus range revoke --user BLUE1 --range CCDC2      # API: revokeRangeFromUser DELETE /ranges/revoke/BLUE1/CCDC2
# Rotate the team's Proxmox password (re-fetch creds resets it)
ludus user creds get --user BLUE1                  # API: getCredentials
# Remove BLUE1 entirely
ludus user rm --user BLUE1                          # API: deleteUser DELETE /user/BLUE1
```

Need more teams? Repeat with `BLUE2`, `BLUE3`, … each assigned `CCDC2` (shared
range) — or build a separate range per team (bump `rangeNumber`) for isolated copies.
