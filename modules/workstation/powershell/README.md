# Hermes.PowerShell

`Hermes.PowerShell` safely manages a clearly marked Project Hermes block inside
the current user's all-hosts PowerShell profile. Existing user content outside
the managed markers is preserved.

The initial profile automatically imports the completed Hermes modules in every
new PowerShell 7 session, eliminating repeated manual imports during development.

## Safety

- Backs up the complete profile before mutation
- Supports `-WhatIf` and `-Confirm`
- Replaces only the marked Hermes block
- Preserves unrelated profile content
- Restores the exact original bytes or removes a profile that did not exist

## Validation

```powershell
Test-ModuleManifest .\modules\workstation\powershell\Hermes.PowerShell.psd1
Import-Module .\modules\workstation\powershell\Hermes.PowerShell.psd1 -Force
Invoke-Pester .\modules\workstation\powershell\tests -Output Detailed
```

Current result: 15 passing tests with no failures.
