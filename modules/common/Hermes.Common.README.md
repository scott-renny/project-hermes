# Hermes.Common

`Hermes.Common` provides shared technical helpers for Project Hermes PowerShell modules.

The module centralizes functionality that would otherwise be duplicated across workstation and developer modules, including standardized logging, environment validation, safe Registry operations, JSON serialization, and Windows Explorer shell restart handling.

## Module Status

| Property | Value |
|---|---|
| Version | 0.1.0 |
| Status | Initial implementation |
| Minimum PowerShell version | 5.1 |
| Supported editions | Desktop and Core |
| Primary platform | Windows 11 |
| Test framework | Pester 6 |

## Responsibilities

`Hermes.Common` owns reusable technical helpers that can be consumed by multiple Project Hermes modules.

Included responsibilities:

- Standardized console and file logging
- Administrator detection
- Operating-system detection
- PowerShell version validation
- Safe Registry reads, writes, and removals
- Registry path validation
- UTF-8 JSON import and export
- Windows Explorer shell restart handling

Module-specific configuration policy does not belong in `Hermes.Common`. Explorer, Taskbar, Windows, Git, VS Code, Terminal, and other modules remain responsible for defining their own desired settings and validation rules.

## Installation

`Hermes.Common` is maintained as part of the Project Hermes repository and does not require a separate installation.

Import it from the repository root:

```powershell
Import-Module `
    .\modules\common\Hermes.Common.psd1 `
    -Force
```

Verify the imported commands:

```powershell
Get-Command -Module Hermes.Common
```

## Exported Commands

### Logging

| Command | Purpose |
|---|---|
| `Write-HermesLog` | Writes a timestamped log entry to the console, a file, or both. |
| `Write-HermesSuccess` | Writes a standardized success entry. |
| `Write-HermesWarning` | Writes a standardized warning entry. |
| `Write-HermesError` | Writes a standardized error entry without terminating execution. |

### Validation

| Command | Purpose |
|---|---|
| `Test-HermesAdministrator` | Determines whether the current process has administrator privileges. |
| `Test-HermesOperatingSystem` | Tests whether the active platform is Windows, Linux, or macOS. |
| `Test-HermesPowerShell` | Tests whether the active PowerShell version meets a minimum requirement. |

### Registry

| Command | Purpose |
|---|---|
| `Test-HermesRegistryPath` | Tests whether a Registry key exists. |
| `Get-HermesRegistryValue` | Reads a Registry value with optional default and strict missing-value behavior. |
| `Set-HermesRegistryValue` | Creates or updates a Registry value with idempotency and `ShouldProcess` support. |
| `Remove-HermesRegistryValue` | Removes a Registry value with missing-value and `ShouldProcess` handling. |

### JSON

| Command | Purpose |
|---|---|
| `Export-HermesJson` | Writes an object as UTF-8 JSON without a byte-order mark. |
| `Import-HermesJson` | Reads and deserializes a UTF-8 JSON document. |

### Windows Shell

| Command | Purpose |
|---|---|
| `Restart-HermesExplorer` | Restarts and verifies the Windows Explorer shell. |

## Usage Examples

### Logging

```powershell
Write-HermesLog `
    -Message 'Beginning workstation validation.' `
    -Level Information

Write-HermesSuccess `
    -Message 'Validation completed successfully.'
```

Write entries to a file without console output:

```powershell
Write-HermesLog `
    -Message 'Configuration loaded.' `
    -Level Success `
    -LogPath '.\logs\hermes.log' `
    -NoConsole
```

### Environment Validation

```powershell
if (-not (Test-HermesOperatingSystem -OperatingSystem Windows)) {
    throw 'This module requires Windows.'
}

if (-not (Test-HermesPowerShell -MinimumVersion '7.0')) {
    throw 'PowerShell 7 or later is required.'
}

if (-not (Test-HermesAdministrator)) {
    Write-HermesWarning -Message 'Administrator privileges are not available.'
}
```

### Reading a Registry Value

```powershell
$Value = Get-HermesRegistryValue `
    -Path 'HKCU:\Software\Example' `
    -Name 'Enabled' `
    -DefaultValue 0
```

Require the value to exist:

```powershell
$Value = Get-HermesRegistryValue `
    -Path 'HKCU:\Software\Example' `
    -Name 'Enabled' `
    -ThrowOnMissing
```

### Setting a Registry Value

```powershell
Set-HermesRegistryValue `
    -Path 'HKCU:\Software\Example' `
    -Name 'Enabled' `
    -Value 1 `
    -Type DWord `
    -CreatePath
```

Preview the operation without changing the Registry:

```powershell
Set-HermesRegistryValue `
    -Path 'HKCU:\Software\Example' `
    -Name 'Enabled' `
    -Value 1 `
    -Type DWord `
    -CreatePath `
    -WhatIf
```

### Removing a Registry Value

```powershell
Remove-HermesRegistryValue `
    -Path 'HKCU:\Software\Example' `
    -Name 'Enabled' `
    -IgnoreMissing
```

### JSON Export and Import

```powershell
$Configuration = [pscustomobject]@{
    Name = 'Hermes'
    Enabled = $true
}

$Configuration |
    Export-HermesJson `
        -Path '.\exports\configuration.json' `
        -Force

$ImportedConfiguration = Import-HermesJson `
    -Path '.\exports\configuration.json'
```

### Restarting Windows Explorer

Preview the restart:

```powershell
Restart-HermesExplorer -WhatIf
```

Perform and verify the restart:

```powershell
Restart-HermesExplorer -TimeoutSeconds 10
```

Restarting Explorer closes and recreates the Windows shell. Applications normally remain open, but taskbar and desktop elements briefly disappear during the restart.

## Return Objects

Mutating helpers return structured objects that describe their result.

`Set-HermesRegistryValue` returns:

```text
Path
Name
Value
Type
Changed
Applied
```

`Remove-HermesRegistryValue` returns:

```text
Path
Name
Existed
Removed
```

`Restart-HermesExplorer` returns:

```text
Requested
Restarted
ProcessId
```

The `Applied`, `Removed`, and `Restarted` properties distinguish a completed operation from a `-WhatIf` preview.

## Safety and Error Handling

- Registry write, removal, JSON export, and Explorer restart operations support `-WhatIf` and `-Confirm`.
- Registry writes are idempotent when the stored value already matches the requested value.
- Missing Registry keys are not created unless `-CreatePath` is specified.
- Existing JSON files are not overwritten unless `-Force` is specified.
- File writes create required parent directories automatically.
- Operational failures throw contextual error messages containing the affected path or operation.
- `Write-HermesError` records an error-level entry but does not throw; callers control termination behavior.

## Validation

Validate the manifest and import the module:

```powershell
Test-ModuleManifest `
    .\modules\common\Hermes.Common.psd1

Remove-Module Hermes.Common -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\common\Hermes.Common.psd1 `
    -Force

Get-Command -Module Hermes.Common
```

Run the Pester suite:

```powershell
Invoke-Pester `
    -Path .\modules\common\tests `
    -Output Detailed
```

The initial validated release contains 48 passing tests.

## Module Structure

```text
modules/common/
├── Hermes.Common.psd1
├── Hermes.Common.psm1
├── README.md
└── tests/
    └── Hermes.Common.Tests.ps1
```

## Development Requirements

Changes to `Hermes.Common` must:

- Preserve PowerShell 5.1 compatibility unless the project standard changes.
- Avoid module-specific policy.
- Include complete comment-based help for every exported command.
- Use `SupportsShouldProcess` for state-changing operations.
- Preserve idempotent behavior where practical.
- Add or update Pester coverage.
- Pass manifest validation, module import, and the complete test suite before commit.

## License

Project Hermes is licensed under the MIT License. See the repository-level `LICENSE` file for details.
