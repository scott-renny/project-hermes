# Hermes.Windows

`Hermes.Windows` v0.5.0 manages a focused set of visible Windows 11 personalization settings through the standard Project Hermes lifecycle.

```text
Discover -> Validate -> Compare -> Back up -> Apply -> Verify -> Restore
```

## Managed settings

| Setting | Values | Effect |
|---|---|---|
| `AppTheme` | `Dark`, `Light` | Selects the theme used by supported applications. |
| `SystemTheme` | `Dark`, `Light` | Selects the Windows shell and system-interface theme. |
| `Transparency` | `Enabled`, `Disabled` | Controls supported Windows transparency effects. |
| `AccentOnTitleBars` | `Enabled`, `Disabled` | Controls accent color on supported title bars and window borders. |

This initial scope is intentionally small. Wallpaper, icons, Rainmeter, Windhawk, PowerToys, and the complete Hermes visual identity remain separate later milestones.

## Public commands

- `Get-HermesWindowsSettings`
- `Test-HermesWindowsConfiguration`
- `Test-HermesWindowsSettings`
- `Backup-HermesWindowsSettings`
- `Set-HermesWindowsSettings`
- `Restore-HermesWindowsSettings`

## Dependencies

- `Hermes.Core` supplies standardized backup creation and reading.
- `Hermes.Common` supplies safe Registry operations and optional Explorer restart handling.

The module requires PowerShell 7.0 or later.

## Import

```powershell
Remove-Module Hermes.Windows -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\workstation\windows\Hermes.Windows.psd1 `
    -Force `
    -ErrorAction Stop
```

## Inspect current state

```powershell
Get-HermesWindowsSettings | Format-List
```

Absent Registry values are reported as `NotConfigured`; unsupported stored values are reported as `Unknown`.

## Define desired state

Configurations may contain one or more managed settings:

```powershell
$configuration = [ordered]@{
    AppTheme          = 'Dark'
    SystemTheme       = 'Dark'
    Transparency      = 'Enabled'
    AccentOnTitleBars = 'Enabled'
}
```

Validate without making changes:

```powershell
Test-HermesWindowsConfiguration -Configuration $configuration
Test-HermesWindowsSettings -Configuration $configuration
```

## Preview visible changes

```powershell
Set-HermesWindowsSettings `
    -Configuration $configuration `
    -WhatIf
```

Preview mode creates no backup and writes no Registry values.

## Apply personalization

```powershell
$result = Set-HermesWindowsSettings `
    -Configuration $configuration `
    -Confirm:$false

$result | Format-List
```

When changes are necessary, the command validates the configuration, creates a backup, applies only the selected settings, verifies the resulting state, and returns a structured result.

Use `-RestartExplorer` only when you are ready for the Windows shell to restart:

```powershell
Set-HermesWindowsSettings `
    -Configuration $configuration `
    -RestartExplorer `
    -Confirm:$false
```

## Backup

```powershell
$backup = Backup-HermesWindowsSettings
$backup | Format-List
```

The version 1.0 module backup stores both readable canonical settings and exact Registry existence/value metadata. This preserves the distinction between configured, unconfigured, and unsupported state.

## Restore

Preview:

```powershell
Restore-HermesWindowsSettings `
    -BackupPath '.\exports\backups\hermes.windows\<backup-file>.json' `
    -WhatIf
```

Restore with a new safety backup:

```powershell
$result = Restore-HermesWindowsSettings `
    -BackupPath '.\exports\backups\hermes.windows\<backup-file>.json' `
    -CreateSafetyBackup `
    -Confirm:$false

$result | Format-List
```

Exact restore writes values that existed and removes only the managed named values that were absent when the backup was created. Legacy backups without exact metadata restore supported canonical values when possible.

## Validation

```powershell
Test-ModuleManifest `
    .\modules\workstation\windows\Hermes.Windows.psd1

Import-Module `
    .\modules\workstation\windows\Hermes.Windows.psd1 `
    -Force

Get-Command -Module Hermes.Windows

Invoke-Pester `
    -Path .\modules\workstation\windows\tests `
    -Output Detailed
```

## Safety characteristics

- User-scoped personalization settings only
- Partial desired-state configurations
- Strict supported-value validation
- Idempotent compliance behavior
- Backup before mutation by default
- Optional pre-restore safety backup
- `ShouldProcess`, `-WhatIf`, and `-Confirm`
- Exact restoration of absent and configured values
- Independent post-change verification
- Explorer restart only when explicitly requested

## Visual expectations

Applying the dark themes and accent settings should produce an immediate, noticeable Windows appearance change in supported surfaces. This is the first Hermes workstation module aimed directly at visible personalization, but it is not yet the complete Hermes visual environment.
