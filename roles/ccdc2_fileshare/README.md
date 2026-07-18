# ccdc2_fileshare

Central **Windows Server 2022** SMB file share for the range, joined to the
**Samba AD** domain (`ccdc.local`).

## What it does
1. Points the NIC's DNS at the Samba DC (`10.51.10.10`) and joins `ccdc.local`
   (reboots). If the join fails, it falls back to local permissions so the share
   still works — re-run after the DC is healthy to switch to AD-group ACLs.
2. Creates `C:\Shares\Departments` with 5 subfolders: HR, Finance, IT, Sales,
   Engineering (each with a placeholder readme).
3. Publishes the `Departments` SMB share.
4. Grants each subfolder **Modify** to its matching AD group (`CCDC\HR`, …) when
   domain-joined, else to local Users.

## Access
`\\10.51.10.30\Departments` (or `\\fs01\Departments`). Department groups are
created on the DC by `ccdc2_samba_dc`; members are the seeded employees.

## Verify
```
Get-SmbShare Departments
Get-ChildItem \\10.51.10.30\Departments
(Get-Acl 'C:\Shares\Departments\HR').Access
```
