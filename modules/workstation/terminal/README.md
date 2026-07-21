# Hermes.Terminal

`Hermes.Terminal` v0.5.0 manages a focused Project Hermes visual baseline in Windows Terminal while preserving unrelated settings and profiles.

## Managed settings

- Application theme
- Default color scheme
- Default font face and size
- Background opacity and acrylic material
- Cursor shape
- The complete `Project Hermes` color scheme

The module discovers Store, Preview, and unpackaged Windows Terminal settings locations. An explicit `-SettingsPath` can be supplied for testing or nonstandard installations.

## Safety model

- Configuration is validated before any write.
- Existing `settings.json` bytes are backed up exactly.
- Unrelated Terminal properties, profiles, actions, and schemes are preserved.
- The managed scheme is replaced by name without duplicating it.
- State changes support `-WhatIf` and `-Confirm`.
- Applied state is independently verified.
- Restore writes the exact prior bytes or removes a file that did not exist.

## Usage

```powershell
Import-Module .\modules\workstation\terminal\Hermes.Terminal.psd1 -Force

$configuration = Import-PowerShellDataFile `
    .\configs\terminal\hermes-terminal-base.psd1

Test-HermesTerminalSettings -Configuration $configuration
Set-HermesTerminalSettings -Configuration $configuration -WhatIf
Set-HermesTerminalSettings -Configuration $configuration -Confirm:$false
```

Windows Terminal may reload `settings.json` automatically. Open a new tab after applying the profile to see all default-profile changes.
