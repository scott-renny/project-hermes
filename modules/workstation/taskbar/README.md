# Hermes.Taskbar

`Hermes.Taskbar` manages selected Windows 11 taskbar settings through a
consistent configuration model.

## Public commands

- `Get-HermesTaskbarSettings`
- `Test-HermesTaskbarConfiguration`
- `Test-HermesTaskbarSettings`
- `Backup-HermesTaskbarSettings`
- `Set-HermesTaskbarSettings`
- `Restore-HermesTaskbarSettings`

## Canonical configuration model

```powershell
$config = @{
    Alignment   = 'Center'
    Search      = 'Hidden'
    TaskView    = 'Enabled'
    Widgets     = 'Disabled'
    Copilot     = 'Disabled'
    AutoHide    = 'Disabled'
    ShowSeconds = 'Enabled'
}
```

The following aliases are accepted for compatibility:

```powershell
$config = @{
    ShowTaskView = $true
    ShowWidgets  = $false
    ShowCopilot  = $false
}
```

The repository includes the initial validated Hermes Taskbar profile:

```text
configs\windows\hermes-taskbar-base.psd1
```

Load it safely as data:

```powershell
$config = Import-PowerShellDataFile `
    -LiteralPath '.\configs\windows\hermes-taskbar-base.psd1'
```

The Windows Home profile uses centered alignment, icon-only Search, enabled Task View, disabled Widgets, a persistent taskbar, and clock seconds. It intentionally leaves Copilot unmanaged because the applicable policy key may reject user-level writes on supported Windows Home installations.

## Native Windows state and Windhawk

`Hermes.Taskbar` manages the native Windows taskbar configuration. Third-party
shell customization tools can change the rendered taskbar without changing the
Registry values reported by this module.

Windhawk mods such as **Vertical Taskbar for Windows 11**, **Windows 11 Taskbar
Styler**, **Taskbar height and icon size**, **Taskbar Clock Customization**, and
taskbar auto-hide or fade mods therefore form a separate visual layer. When one
of these mods is active, `Test-HermesTaskbarSettings` can correctly report native
compliance even though the visible taskbar has a different position, size,
appearance, clock, or hide behavior.

Validate the native Hermes baseline with taskbar-affecting Windhawk mods disabled.
Windhawk configuration will be introduced later as an optional, profile-controlled
integration and will not be treated as part of the native Taskbar contract.

## Validate and compare

```powershell
Test-HermesTaskbarConfiguration -Configuration $config
Test-HermesTaskbarSettings -Configuration $config
```

## Preview changes

```powershell
Set-HermesTaskbarSettings -Configuration $config -WhatIf
```

## Apply changes

```powershell
Set-HermesTaskbarSettings `
    -Configuration $config `
    -RestartExplorer
```

A safety backup is created automatically unless `-SkipBackup` is used.

## Backup and restore

```powershell
$backup = Backup-HermesTaskbarSettings

Restore-HermesTaskbarSettings `
    -BackupPath $backup.Path `
    -CreateSafetyBackup `
    -RestartExplorer
```

## Run tests

From the repository root:

```powershell
Invoke-Pester .\modules\workstation\taskbar\tests
```
