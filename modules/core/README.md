# Hermes.Core

`Hermes.Core` provides shared infrastructure for Project Hermes modules.

## Exported commands

- `Get-HermesRepositoryRoot`
- `Get-HermesVersion`
- `New-HermesGuid`
- `Write-HermesBackup`
- `Read-HermesBackup`

## Default backup location

```text
exports\backups\<module-name>
```

## Run tests

```powershell
Invoke-Pester `
    .\modules\core\tests\Hermes.Core.Tests.ps1 `
    -Output Detailed
```
