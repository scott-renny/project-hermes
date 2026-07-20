# Hermes.Explorer

`Hermes.Explorer` safely manages selected Windows File Explorer preferences.

## Current capabilities

- Read current Explorer settings
- Validate desired configuration
- Compare current and desired state
- Create standardized backups through `Hermes.Core`
- Apply settings with automatic pre-change backup
- Verify settings after application
- Preview changes with `-WhatIf`

## Managed settings

| Hermes setting | Registry value |
|---|---|
| `ShowFileExtensions` | `HideFileExt` |
| `ShowHiddenFiles` | `Hidden` |
| `LaunchExplorerTo` | `LaunchTo` |

## Example configuration

```powershell
$configuration = [PSCustomObject]@{
    showFileExtensions = $true
    showHiddenFiles    = $true
    launchExplorerTo   = 'ThisPC'
}
```

Preview the operation:

```powershell
Set-HermesExplorerSettings `
    -Configuration $configuration `
    -WhatIf
```

Apply the configuration:

```powershell
$result = Set-HermesExplorerSettings `
    -Configuration $configuration

$result | Format-List
```

## Safety behavior

Hermes performs the following sequence:

1. Validate configuration
2. Compare current state
3. Create a backup
4. Write registry values
5. Read the settings again
6. Verify compliance

No backup is created when the machine is already compliant or when `-WhatIf`
prevents the operation.

## Dependency

```text
modules\core\Hermes.Core.psd1
```

## Tests

```powershell
Invoke-Pester `
    .\modules\workstation\explorer\tests\Hermes.Explorer.Tests.ps1 `
    -Output Detailed
```
