# Hermes.Git

`Hermes.Git` v0.5.0 manages a focused set of user-level Git defaults through the standard Project Hermes lifecycle.

## Managed settings

- Default initial branch name
- Windows line-ending conversion and safety checks
- Automatic pruning during fetch
- Pull rebase strategy
- Automatic upstream setup on first push
- Git Credential Manager helper selection

Hermes deliberately does not manage `user.name`, `user.email`, credentials, repository-local configuration, conditional includes, aliases, signing keys, or system-level Git configuration.

## Safety model

- Git must already be installed and available on `PATH`.
- Configuration is validated before mutation.
- Only explicit supported keys are written at `--global` scope.
- Each managed key's prior existence and value are backed up.
- Missing prior values are restored by removing only that managed key.
- State changes support `-WhatIf` and `-Confirm`.
- Applied state is independently verified.
- Repeated compliant application is idempotent.

## Usage

```powershell
Import-Module .\modules\workstation\git\Hermes.Git.psd1 -Force

$configuration = Import-PowerShellDataFile `
    .\configs\git\hermes-git-base.psd1

Get-HermesGitSettings
Test-HermesGitSettings -Configuration $configuration
Set-HermesGitSettings -Configuration $configuration -WhatIf
Set-HermesGitSettings -Configuration $configuration -Confirm:$false
```

The baseline uses `core.autocrlf=true` because Windows 11 is Project Hermes' primary platform. Repository-level `.gitattributes` remains authoritative for files with explicit line-ending rules.
