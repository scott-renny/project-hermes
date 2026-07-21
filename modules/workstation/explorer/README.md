# Hermes.Explorer

`Hermes.Explorer` v0.4.0 manages selected Windows Explorer user settings through a validated and reversible configuration lifecycle.

```text
Discover -> Validate -> Compare -> Back up -> Apply -> Verify -> Restore
```

## Managed settings

| Setting | Supported values | Registry value |
|---|---|---|
| Show file extensions | Boolean | `HideFileExt` |
| Show hidden files | Boolean | `Hidden` |
| Launch Explorer to | `ThisPC`, `Home` | `LaunchTo` |

All managed values are stored beneath:

```text
HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
```

## Public commands

- `Get-HermesExplorerSettings`
- `Test-HermesExplorerConfiguration`
- `Test-HermesExplorerSettings`
- `Backup-HermesExplorerSettings`
- `Set-HermesExplorerSettings`
- `Restore-HermesExplorerSettings`

## Dependencies

`Hermes.Explorer` uses:

- `Hermes.Core` for standardized backup creation and reading.
- `Hermes.Common` for safe, consistent Registry reads, writes, and removals.

The module resolves both dependencies from the Project Hermes repository and stops during import with a clear error when either manifest is unavailable.

## Import

From the repository root:

```powershell
Remove-Module Hermes.Explorer -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\workstation\explorer\Hermes.Explorer.psd1 `
    -Force `
    -ErrorAction Stop
```

## Inspect current state

```powershell
Get-HermesExplorerSettings | Format-List
```

Example result:

```text
ShowFileExtensions : True
ShowHiddenFiles    : False
LaunchExplorerTo   : Home
```

An absent `LaunchTo` value is reported as `NotConfigured`. Unsupported values are reported as `Unknown` rather than silently mapped to a supported state.

## Validate desired state

```powershell
$configuration = [pscustomobject]@{
    showFileExtensions = $true
    showHiddenFiles    = $false
    launchExplorerTo   = 'ThisPC'
}

Test-HermesExplorerConfiguration `
    -Configuration $configuration
```

The configuration must contain all three properties. The two visibility settings must be Boolean values, and `launchExplorerTo` must be either `ThisPC` or `Home`.

## Test compliance

```powershell
Test-HermesExplorerSettings `
    -Configuration $configuration |
    Format-List
```

The result identifies whether the workstation is compliant and reports each current and desired value that differs.

## Create a backup

```powershell
$backup = Backup-HermesExplorerSettings
$backup | Format-List
```

By default, `Hermes.Core` stores Explorer backups beneath:

```text
exports\backups\explorer
```

A custom destination can be supplied with `-BackupDirectory`.

## Preview configuration

```powershell
Set-HermesExplorerSettings `
    -Configuration $configuration `
    -WhatIf
```

Preview mode does not create a backup or write Registry values.

## Apply configuration

```powershell
$result = Set-HermesExplorerSettings `
    -Configuration $configuration `
    -Confirm:$false

$result | Format-List
```

When a change is required, the command:

1. Validates the desired configuration.
2. Compares it with current state.
3. Creates a safety backup.
4. Applies the managed Registry values through `Hermes.Common`.
5. Reads the resulting state independently.
6. Throws when verification fails.

Repeated execution is idempotent. No backup or Registry write occurs when the current state already matches the desired state.

## Restore a backup

Preview first:

```powershell
Restore-HermesExplorerSettings `
    -BackupPath '.\exports\backups\explorer\<backup-file>.json' `
    -WhatIf
```

Restore after reviewing the preview:

```powershell
$result = Restore-HermesExplorerSettings `
    -BackupPath '.\exports\backups\explorer\<backup-file>.json' `
    -Confirm:$false

$result | Format-List
```

Restore validates the source module and saved values, creates a new safety backup, applies the saved state, and verifies the result. When the backup records `LaunchExplorerTo` as `NotConfigured`, the module removes only the `LaunchTo` Registry value instead of guessing a replacement.

## Explorer restart

Successful apply and restore results set:

```text
RestartExplorerRequired = True
```

The module reports this requirement without automatically restarting the active Windows shell. Callers can choose an appropriate restart time and use `Restart-HermesExplorer` from `Hermes.Common` when desired.

## Validation

From the repository root:

```powershell
Test-ModuleManifest `
    .\modules\workstation\explorer\Hermes.Explorer.psd1

Remove-Module Hermes.Explorer -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\workstation\explorer\Hermes.Explorer.psd1 `
    -Force

Get-Command -Module Hermes.Explorer

Invoke-Pester `
    -Path .\modules\workstation\explorer\tests `
    -Output Detailed
```

## Safety characteristics

- User-scoped Registry changes only.
- Strict configuration validation.
- Backup before mutation.
- Safety backup before restoration.
- Idempotent compliance behavior.
- `ShouldProcess`, `-WhatIf`, and `-Confirm` support.
- Contextual errors containing the recovery backup path.
- Independent post-change verification.
- No automatic Windows Explorer restart.

## Platform

The module is designed for Windows 11 and the current Project Hermes workstation architecture. The manifest targets PowerShell 5.1 compatibility while PowerShell 7+ remains the primary development and validation environment.
