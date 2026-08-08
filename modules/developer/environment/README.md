# Hermes.Developer

`Hermes.Developer` provisions and validates the native Windows developer environment introduced in Project Hermes v0.6.0.

The module manages only the Windows client boundary:

- required developer command availability;
- approved WinGet package installation;
- required Visual Studio Code extensions;
- Windows `ssh-agent` readiness and loaded-key state;
- configured OpenSSH host aliases;
- bounded, explicit Remote SSH connectivity tests; and
- informational reporting for optional WSL, Docker, Python, Node.js, and .NET capabilities, distinguishing a detected launcher from an operational runtime.

It does not install optional runtimes unconditionally and does not manage the remote Ubuntu server, its containers, secrets, backups, or repositories.

## Typical workflow

```powershell
Import-Module .\modules\developer\environment\Hermes.Developer.psd1 -Force
$configuration = Import-PowerShellDataFile .\configs\developer\hermes-developer-base.psd1

Test-HermesDeveloperConfiguration -Configuration $configuration
Get-HermesDeveloperEnvironment -Configuration $configuration
Test-HermesDeveloperEnvironment -Configuration $configuration
Set-HermesDeveloperEnvironment -Configuration $configuration -WhatIf
Test-HermesRemoteHost -HostName coc-srv-01
```

Use `Export-HermesDeveloperInventory` to write a reviewable JSON inventory under the ignored `exports` tree.
