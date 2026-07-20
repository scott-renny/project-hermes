# Hermes.Explorer

`Hermes.Explorer` manages Windows File Explorer preferences for Project Hermes.

## Current capabilities

- Read current Explorer settings
- Compare current settings with desired configuration
- Create standardized backups through `Hermes.Core`

## Planned capabilities

- Apply desired Explorer settings
- Restore Explorer settings from a Hermes backup
- Verify changes after application or restoration

## Dependency

This module loads:

```text
modules\core\Hermes.Core.psd1
```

## Tests

From the Project Hermes repository root:

```powershell
Invoke-Pester `
    .\modules\workstation\explorer\tests\Hermes.Explorer.Tests.ps1 `
    -Output Detailed
```
