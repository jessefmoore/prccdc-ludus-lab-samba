# Create a Team User with Console-Only Access

How to give a competition team **console-only** access to the `CCDC2` range —
they can open each VM's screen (Proxmox noVNC console) but **cannot** build
templates, touch other ranges, get a host shell, or admin the server.

## How it works
Every Ludus user gets a **Proxmox account scoped to the resource pool of the
range(s) assigned to them**. A *non-admin* user who is assigned `CCDC2` sees only
the `CCDC2` pool in the Proxmox web UI and can open the **Console** of those VMs —
exactly "console-only." No range assignment = nothing to see.

So it's two steps: **(1) add a non-admin user**, **(2) assign the range to them**.
Do this as a Ludus **admin** (e.g. `JM`). Nothing needs redeploying.

---

## Option A — Ludus CLI

```bash
# 1. Create a NON-admin user (no --admin flag)
ludus user add --name "PRCCDC Blue Team 1" --userid BLUE1
#   (add --admin ONLY for admins — do NOT here)

# 2. Assign the CCDC2 range -> grants scoped Proxmox console access
ludus range assign --user BLUE1 --range CCDC2

# 3. Get the team's Proxmox login to hand out
ludus user creds get --user BLUE1
```

## Option B — Ludus MCP / REST API

```jsonc
// 1. addUser  (POST /user)  — isAdmin MUST be false; email is required
{ "name": "PRCCDC Blue Team 1", "userID": "BLUE1",
  "isAdmin": false, "email": "blue1@ccdc.local",
  "password": "CCDC2-Blue1-2026!" }        // optional; omit to auto-generate

// 2. assignRangeToUser  (POST /ranges/assign/BLUE1/CCDC2)   — path params, no body

// 3. getCredentials  (GET /user/credentials?userID=BLUE1)
//    -> { proxmoxUsername, proxmoxPassword, proxmoxRealm: "pam", ludusEmail }
```

Admin note: as admin you can operate on their range with the `userID` query param
(e.g. `deployRange userID=BLUE1`, `listRange userID=BLUE1`).

---

## How the team logs in
- **Proxmox web console:** browse to `https://<proxmox-host>:8006`
  (this deployment: `https://192.168.0.193:8006`), **Realm = `Linux PAM` (pam)**,
  and the `proxmoxUsername` / `proxmoxPassword` from step 3.
- They see only the **`CCDC2`** pool → click a VM → **Console** (noVNC) to drive it.
- Optional embedded console: `getConsoleWebsocketTicket` (GET `/vm/console/ticket`)
  returns a one-time ticket to embed the noVNC console in your own page/Guacamole.

## What they can / cannot do
| ✅ Can | ❌ Cannot |
|-------|----------|
| See the `CCDC2` pool's VMs in Proxmox | See any other range/pool |
| Open each VM's noVNC **Console** | Build/delete templates |
| Power on/off/reset **their** VMs | Get a Proxmox host shell / root |
| — | Admin the Ludus server or other users |

> Console-only means they work **through the VM screen**, like sitting at the
> keyboard. They do **not** automatically get WireGuard/SSH into the range — grant
> that separately (`getWireguardConfig`) only if you want off-console network access.

---

## Manage / clean up
```bash
# List who has access to the range
#   API: listRangeUsers   GET /ranges/CCDC2/users
# Revoke range access (keeps the user)
ludus range revoke --user BLUE1 --range CCDC2      # API: revokeRangeFromUser
# Remove the user entirely
ludus user rm --user BLUE1                          # API: deleteUser  DELETE /user/BLUE1
```

## Multiple teams
Repeat with distinct IDs (`BLUE1`, `BLUE2`, …). Each gets its own scoped Proxmox
account. To give several teams the **same** range, assign `CCDC2` to each; to give
each team an **isolated copy**, build a separate range per team (bump `rangeNumber`
so IPs don't collide) and assign one to each.
