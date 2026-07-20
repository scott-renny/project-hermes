# Hermes.Core

`Hermes.Core` v0.1.1 provides repository-aware infrastructure and the standardized backup contract used by Project Hermes component modules.

## Responsibility

Core owns framework identity and persistent Hermes data contracts:

- Repository-root discovery
- Project version discovery
- Hermes identifier generation
- Standardized backup creation
- Backup schema and module validation
- Standardized backup reading
- Default backup-path resolution

Core does not own Windows Registry access, console presentation, general JSON file utilities, environment validation, Windows shell control, or component policy. Those reusable technical operations belong to `Hermes.Common`.

## Exported commands

- `Get-HermesRepositoryRoot`
- `Get-HermesVersion`
- `New-HermesGuid`
- `Write-HermesBackup`
- `Read-HermesBackup`

## PowerShell requirement

`Hermes.Core` requires PowerShell 7.0 or later. Any module that imports Core must declare the same or a newer minimum version.

## Import

```powershell
Remove-Module Hermes.Core -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\core\Hermes.Core.psd1 `
    -Force `
    -ErrorAction Stop
```

## Repository discovery

```powershell
Get-HermesRepositoryRoot
Get-HermesVersion
```

Repository discovery lets modules use standardized storage without embedding machine-specific absolute paths.

## Create a backup

```powershell
$settings = [pscustomobject]@{
    Enabled = $true
    Mode    = 'Example'
}

$backup = Write-HermesBackup `
    -ModuleName 'Example' `
    -Settings $settings

$backup | Format-List
```

The default destination is:

```text
exports\backups\<module-name>
```

Callers may provide a custom backup directory and additional metadata when their restore contract requires lossless component-specific state.

## Read a backup

```powershell
$backup = Read-HermesBackup `
    -BackupPath '.\exports\backups\example\<backup-file>.json'

$backup | Format-List
```

Core validates the Hermes backup envelope before returning it. Component modules remain responsible for validating their saved settings and confirming the expected module identity.

## Dependency rules

- `Hermes.Core` does not import `Hermes.Common`.
- `Hermes.Common` does not import `Hermes.Core`.
- Component modules may import either or both according to their requirements.
- Component-specific policy must not be placed in either shared module.
- Backup-envelope evolution belongs to Core; component metadata belongs to its component.

See [`docs/reference/shared-module-architecture.md`](../../docs/reference/shared-module-architecture.md) for the authoritative boundary.

## Validation

```powershell
Test-ModuleManifest `
    .\modules\core\Hermes.Core.psd1

Invoke-Pester `
    -Path .\modules\core\tests `
    -Output Detailed
```

## Safety characteristics

- Explicit exported API
- Versioned backup envelope
- Module identity validation
- Repository-relative default output
- UTF-8 JSON backup storage
- Contextual validation errors
- No workstation configuration policy
