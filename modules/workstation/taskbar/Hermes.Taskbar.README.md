# Hermes.Taskbar

`Hermes.Taskbar` reads, validates, backs up, applies, verifies, and restores selected Windows 11 taskbar settings for Project Hermes.

The module follows the Project Hermes workstation lifecycle and uses shared modules for infrastructure:

```text
Hermes.Taskbar
├── Hermes.Core   → standardized backup documents
└── Hermes.Common → Registry operations and Explorer restart handling
```

## Module Status

| Property | Value |
|---|---|
| Version | 0.5.0 |
| Status | Implemented and tested |
| Primary platform | Windows 11 Home |
| Minimum PowerShell version | 7.0 |
| Test framework | Pester 6 |
| Validated tests | 48 passing, 0 failing |

## Managed Settings

| Setting | Supported Values | Registry Source |
|---|---|---|
| `Alignment` | `Left`, `Center` | `TaskbarAl` |
| `Search` | `Hidden`, `Icon`, `Box`, `IconAndLabel` | `SearchboxTaskbarMode` |
| `TaskView` | Boolean, `Enabled`, `Disabled` | `ShowTaskViewButton` |
| `Widgets` | Boolean, `Enabled`, `Disabled` | `TaskbarDa` |
| `Copilot` | Boolean, `Enabled`, `Disabled` | `TurnOffWindowsCopilot` policy |
| `AutoHide` | Boolean, `Enabled`, `Disabled` | `StuckRects3\Settings` binary data |
| `ShowSeconds` | Boolean, `Enabled`, `Disabled` | `ShowSecondsInSystemClock` |

The module may report two additional observed states:

- `NotConfigured` — the related Registry value does not exist.
- `Unknown` — a Registry value exists but is not recognized or safely supported.

`Unknown` values are not automatically restored as canonical configuration.

## Public Commands

| Command | Purpose |
|---|---|
| `Get-HermesTaskbarSettings` | Reads the current managed Taskbar state. |
| `Test-HermesTaskbarConfiguration` | Validates and canonicalizes desired configuration. |
| `Test-HermesTaskbarSettings` | Compares current and desired settings. |
| `Backup-HermesTaskbarSettings` | Creates a standardized Hermes Taskbar backup. |
| `Set-HermesTaskbarSettings` | Backs up, applies, and verifies desired settings. |
| `Restore-HermesTaskbarSettings` | Restores and verifies settings from a Hermes backup. |

## Import

From the Project Hermes repository root:

```powershell
Import-Module `
    .\modules\workstation\taskbar\Hermes.Taskbar.psd1 `
    -Force
```

Inspect the public commands:

```powershell
Get-Command -Module Hermes.Taskbar
```

## Reading Current Settings

```powershell
Get-HermesTaskbarSettings
```

Example shape:

```text
Alignment   : Center
Search      : Icon
TaskView    : Enabled
Widgets     : Disabled
Copilot     : NotConfigured
AutoHide    : Disabled
ShowSeconds : Enabled
```

These values represent the managed Registry state. Some visual changes may not appear until Windows Explorer restarts or the user signs out and back in.

## Desired Configuration

A complete configuration can be represented as a hashtable:

```powershell
$Configuration = @{
    Alignment = 'Center'
    Search = 'Icon'
    TaskView = 'Enabled'
    Widgets = 'Disabled'
    Copilot = 'Disabled'
    AutoHide = 'Disabled'
    ShowSeconds = 'Enabled'
}
```

Boolean values are also accepted for binary settings:

```powershell
$Configuration = @{
    TaskView = $true
    Widgets = $false
    Copilot = $false
    AutoHide = $false
    ShowSeconds = $true
}
```

Supported aliases:

| Alias | Canonical Property |
|---|---|
| `ShowTaskView` | `TaskView` |
| `ShowWidgets` | `Widgets` |
| `ShowCopilot` | `Copilot` |

A configuration cannot contain both an alias and its canonical property.

## Validating Configuration

```powershell
$Validation = Test-HermesTaskbarConfiguration `
    -Configuration $Configuration

$Validation.IsValid
$Validation.Errors
$Validation.Configuration
```

Validation rejects:

- Empty configurations
- Unsupported properties
- Duplicate canonical aliases
- Unsupported Alignment values
- Unsupported Search values
- Unsupported binary-state values

## Testing Compliance

```powershell
$Compliance = Test-HermesTaskbarSettings `
    -Configuration $Configuration

$Compliance.IsCompliant
$Compliance.Differences
```

Each difference contains:

```text
Setting
Expected
Actual
```

## Creating a Backup

```powershell
$Backup = Backup-HermesTaskbarSettings
```

The default destination is managed by `Hermes.Core`:

```text
exports/backups/taskbar/
```

Use a custom directory when required:

```powershell
$Backup = Backup-HermesTaskbarSettings `
    -BackupDirectory 'C:\HermesBackups\Taskbar'
```

### Backup Contents

Taskbar backups use the standard Hermes Core backup schema and contain:

- Schema version
- Module name
- Backup identifier
- Creation timestamp
- Computer and user metadata
- Canonical Taskbar settings
- Taskbar backup format metadata
- Raw AutoHide Registry bytes encoded as Base64

Raw AutoHide data is preserved because `StuckRects3\Settings` is a binary structure containing more information than the managed enabled/disabled state.

## Applying Settings

Preview an operation:

```powershell
Set-HermesTaskbarSettings `
    -Configuration $Configuration `
    -WhatIf
```

Apply, back up, and verify:

```powershell
$Result = Set-HermesTaskbarSettings `
    -Configuration $Configuration `
    -Confirm:$false
```

Apply and restart Windows Explorer after verification:

```powershell
$Result = Set-HermesTaskbarSettings `
    -Configuration $Configuration `
    -RestartExplorer `
    -Confirm:$false
```

Skip the automatic backup only when another verified recovery point already exists:

```powershell
Set-HermesTaskbarSettings `
    -Configuration $Configuration `
    -SkipBackup `
    -Confirm:$false
```

Skipping backup reduces recoverability and should not be the normal workflow.

### Apply Result

The change result includes:

```text
Changed
Backup
Before
After
Verification
ExplorerRestarted
```

If current settings already match, the module returns `Changed = False` and does not create an unnecessary backup or write Registry values.

## Restoring Settings

Preview a restore:

```powershell
Restore-HermesTaskbarSettings `
    -BackupPath '.\exports\backups\taskbar\Hermes.Taskbar-example.json' `
    -WhatIf
```

Restore and verify:

```powershell
$Result = Restore-HermesTaskbarSettings `
    -BackupPath '.\exports\backups\taskbar\Hermes.Taskbar-example.json' `
    -Confirm:$false
```

Create a safety backup before restoring:

```powershell
$Result = Restore-HermesTaskbarSettings `
    -BackupPath '.\exports\backups\taskbar\Hermes.Taskbar-example.json' `
    -CreateSafetyBackup `
    -Confirm:$false
```

Restart Explorer after successful verification:

```powershell
$Result = Restore-HermesTaskbarSettings `
    -BackupPath '.\exports\backups\taskbar\Hermes.Taskbar-example.json' `
    -CreateSafetyBackup `
    -RestartExplorer `
    -Confirm:$false
```

### Exact Restore Behavior

Taskbar restore handles state as follows:

- Configured canonical values are reapplied.
- `NotConfigured` values remove only the corresponding named Registry value.
- Raw AutoHide binary data is restored from version 2.0 Taskbar backup metadata.
- A missing original AutoHide value is restored by removing only `StuckRects3\Settings`.
- Legacy backups without raw AutoHide metadata remain readable.
- `Unknown` canonical values are excluded from automatic restore.
- Final state is independently read and compared with the backed-up canonical settings.

Restore fails when:

- The file is missing or malformed.
- The backup belongs to another Hermes module.
- No settings are safely restorable.
- AutoHide metadata claims a value exists but contains invalid Base64 data.
- Final verification does not match the backup.

## Windows 11 Home Compatibility

The module is designed for Windows 11 Home.

Important limitations:

- Registry values and visible Taskbar features can change across Windows builds.
- Copilot availability is controlled by the installed Windows build and Microsoft feature rollout; setting the policy value does not guarantee the UI exists.
- Search presentation options may vary by build.
- Clock seconds require a Windows build that supports `ShowSecondsInSystemClock`.
- AutoHide uses an undocumented binary Registry structure and is modified conservatively.

Unsupported observed values are reported as `Unknown` rather than guessed.

## Safety Model

- Desired configuration is validated before mutation.
- Compliance is checked before backup or Registry writes.
- A backup is created by default before applying changes.
- State-changing commands support `-WhatIf` and `-Confirm`.
- Registry operations use `Hermes.Common`.
- Backup documents use `Hermes.Core`.
- Applied and restored state is verified after modification.
- Explorer restart is optional and occurs only after verification.
- Errors include contextual operation information.

## Validation

Validate and import the module:

```powershell
Test-ModuleManifest `
    .\modules\workstation\taskbar\Hermes.Taskbar.psd1

Remove-Module Hermes.Taskbar -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\workstation\taskbar\Hermes.Taskbar.psd1 `
    -Force

Get-Command -Module Hermes.Taskbar
```

Run the Pester suite:

```powershell
Invoke-Pester `
    -Path .\modules\workstation\taskbar\tests `
    -Output Detailed
```

Validated result:

```text
Tests Passed: 48
Tests Failed: 0
Tests Skipped: 0
```

Tests mock Registry writes and Explorer restart operations. They do not apply Taskbar changes to the active workstation.

## Module Structure

```text
modules/workstation/taskbar/
├── Hermes.Taskbar.psd1
├── Hermes.Taskbar.psm1
├── README.md
└── tests/
    └── Hermes.Taskbar.Tests.ps1
```

## Dependencies

### Hermes.Core

Provides:

- `Write-HermesBackup`
- `Read-HermesBackup`
- Standard backup schema and repository-relative backup locations

### Hermes.Common

Provides:

- Registry reads, writes, and removals
- Explorer restart behavior
- Shared validation and error-handling foundations

Both dependency manifests are resolved relative to the Taskbar module’s location. Import fails clearly when either dependency is missing.

## Development Requirements

Changes to `Hermes.Taskbar` must:

- Preserve its module GUID.
- Keep public exports synchronized with the manifest.
- Retain the standard six-command workstation lifecycle.
- Preserve backup compatibility where practical.
- Treat unknown Registry data conservatively.
- Update complete help and module documentation.
- Add or update Pester coverage.
- Pass manifest validation, import, export inspection, and the full suite before commit.

## License

Project Hermes is licensed under the MIT License. See the repository-level `LICENSE` file for details.
