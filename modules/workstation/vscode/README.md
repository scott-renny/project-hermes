# Hermes.VSCode

`Hermes.VSCode` v0.5.0 manages selected Visual Studio Code user settings while preserving unrelated values.

The module discovers stable, Insiders, and portable settings locations; validates desired state; backs up the exact original bytes; parses JSONC comments and trailing commas; supports `-WhatIf`; verifies applied state; and restores the exact file or removes a file that did not originally exist.

The initial profile manages theme, editor font, font size, format on save, auto-save, integrated PowerShell, Git auto-fetch, telemetry, and Workspace Trust. Extensions are preserved and remain outside this v0.5.0 settings lifecycle.

```powershell
Import-Module .\modules\workstation\vscode\Hermes.VSCode.psd1 -Force
$config=Import-PowerShellDataFile .\configs\vscode\hermes-vscode-base.psd1
Test-HermesVSCodeSettings $config
Set-HermesVSCodeSettings $config -WhatIf
Set-HermesVSCodeSettings $config -Confirm:$false
```

When applying a change, JSONC comments and formatting are normalized to standard JSON. The exact pre-change bytes remain recoverable from the automatic backup.
