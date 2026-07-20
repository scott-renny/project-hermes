# Hermes.Explorer v0.4.0

This release completes the Explorer module lifecycle:

```text
Validate -> Compare -> Backup -> Apply -> Verify -> Restore
```

## Replacement files

Copy both files into:

```text
modules\workstation\explorer\
```

- `Hermes.Explorer.psm1`
- `Hermes.Explorer.psd1`

## Import

```powershell
Remove-Module Hermes.Explorer -Force -ErrorAction SilentlyContinue
Import-Module .\modules\workstation\explorer\Hermes.Explorer.psd1 -Force -ErrorAction Stop
```

## Preview the restore

Use the first real Explorer backup created during v0.3.1 validation:

```powershell
$backupPath = '.\exports\backups\explorer\Hermes.Explorer-20260720-010109-461.json'

Restore-HermesExplorerSettings `
    -BackupPath $backupPath `
    -WhatIf |
    Format-List
```

## Perform the restore

```powershell
$restoreResult = Restore-HermesExplorerSettings `
    -BackupPath $backupPath `
    -Confirm:$false

$restoreResult | Format-List
```

The restore creates a new safety backup before changing the registry.

## Verify

```powershell
Get-HermesExplorerSettings | Format-List
```

Expected restored state from the cited backup:

```text
ShowFileExtensions : True
ShowHiddenFiles    : False
LaunchExplorerTo   : NotConfigured
```

Explorer v0.4.0 restores `NotConfigured` correctly by removing the `LaunchTo` registry value instead of guessing a replacement.
