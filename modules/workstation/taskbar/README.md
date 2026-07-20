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
