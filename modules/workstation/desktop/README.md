# Hermes.Desktop

`Hermes.Desktop` manages selected native Windows 11 desktop settings through
the standard Project Hermes discovery, validation, compliance, backup, apply,
verification, and restore lifecycle.

## Managed settings

- `WallpaperPath`: repository-relative or absolute path to an existing wallpaper file
- `WallpaperStyle`: `Fill`, `Fit`, `Stretch`, `Center`, `Tile`, or `Span`
- `DesktopIcons`: `Shown` or `Hidden`

Adobe Creative Cloud and other design tools produce wallpaper assets; they do
not form a runtime dependency of this module. The module accepts an exported
image path through configuration so the visual asset can evolve independently.

## Public commands

- `Get-HermesDesktopSettings`
- `Test-HermesDesktopConfiguration`
- `Test-HermesDesktopSettings`
- `Backup-HermesDesktopSettings`
- `Set-HermesDesktopSettings`
- `Restore-HermesDesktopSettings`

## Example

```powershell
$configuration = @{
    WallpaperPath  = 'assets\wallpapers\hermes-wallpaper-concept-v2.png'
    WallpaperStyle = 'Fill'
    DesktopIcons   = 'Hidden'
}

Test-HermesDesktopSettings -Configuration $configuration
Set-HermesDesktopSettings -Configuration $configuration -WhatIf
Set-HermesDesktopSettings -Configuration $configuration -RestartExplorer
```

An automatic safety backup is created before changes unless `-SkipBackup` is
explicitly supplied. Restore uses exact Registry metadata from the backup.

Repository-relative wallpaper paths are resolved through `Hermes.Core`, keeping
version-controlled profiles portable across users and clone locations.

## Validation

```powershell
Test-ModuleManifest .\modules\workstation\desktop\Hermes.Desktop.psd1
Import-Module .\modules\workstation\desktop\Hermes.Desktop.psd1 -Force
Get-Command -Module Hermes.Desktop
Invoke-Pester .\modules\workstation\desktop\tests -Output Detailed
```

The Desktop suite also validates the version-controlled native profile and its
repository-relative wallpaper resolution.

Current result: 25 passing tests with no failures.
