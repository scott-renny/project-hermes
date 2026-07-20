# Build Journal

The Project Hermes Build Journal records implementation history, engineering decisions, validation evidence, problems encountered, corrective action, and lessons learned.

Release-focused changes belong in `CHANGELOG.md`. This document preserves the reasoning and operational history behind those changes.

---

## v0.5.0 — Workstation Framework

**Status:** In progress  
**Development Branch:** `feature/v0.5-workstation`  
**Started:** July 19, 2026  
**Last Updated:** July 20, 2026

### Objective

Build a modular workstation configuration framework capable of safely reading, validating, backing up, applying, verifying, and restoring Windows user configuration.

The milestone establishes a reusable module lifecycle rather than a collection of one-time customization scripts.

### Planned Workstation Lifecycle

```text
Read current settings
        ↓
Validate desired configuration
        ↓
Back up current settings
        ↓
Apply desired settings
        ↓
Verify resulting state
        ↓
Restore from backup when required
```

### Current Milestone Status

| Component | Status |
|---|---|
| Repository cleanup | Complete |
| `Hermes.Explorer` lifecycle | Complete and tested |
| `Hermes.Common` v0.1.0 | Complete and tested |
| `Hermes.Taskbar` v0.5.0 | Complete and tested |
| Remaining workstation modules | Planned |
| v0.5.0 integration validation | Planned |

---

### Repository Cleanup

#### Work Completed

- Removed temporary `.bak` documentation files.
- Removed the dated Taskbar backup directory from the source tree.
- Added ignore rules for generated runtime data.
- Preserved required runtime folder structure with `.gitkeep` files.
- Removed generated logs, baselines, backups, state, and summaries from Git tracking while retaining local copies.
- Removed the obsolete `feature/v0.4-validation` branch after confirming it contained no commits unique from `main`.

#### Generated Data Policy

The following data remains local by default:

```text
logs/*
exports/backups/*
exports/baseline/*
exports/state/*
exports/summaries/*
```

This protects workstation-specific data and prevents runtime artifacts from obscuring source changes.

#### Lesson Learned

Generated operational evidence is valuable locally but should not automatically become public repository content. Source, templates, and examples must be separated from machine-specific output.

---

### Hermes.Explorer v0.4.0

#### Objective

Complete the Windows Explorer configuration lifecycle and establish a reference pattern for future workstation modules.

#### Work Completed

- Implemented validated Explorer settings restoration.
- Verified backup files belong to the Explorer module before use.
- Validated required backup properties and supported values.
- Added idempotent behavior when current settings already match the backup.
- Created a safety backup before applying restored values.
- Added Registry write error handling.
- Added post-restore verification.
- Added `ShouldProcess` and `-WhatIf` support.
- Updated the module manifest and documentation.
- Replaced the obsolete restore placeholder test with implementation coverage.

#### Validation

The module passed:

- `Test-ModuleManifest`
- Module import
- Public command export inspection
- Complete Explorer Pester suite

#### Problem Encountered

The first Pester run contained one failing test named as though restore was not implemented. The implementation correctly rejected a missing backup file, while the outdated test still expected the former placeholder exception.

#### Corrective Action

The complete test file was replaced with coverage for the implemented restore workflow, including:

- Missing backup files
- Incorrect module identity
- Invalid saved settings
- Idempotent restore behavior
- `-WhatIf`
- Safety backup creation
- Registry restoration
- `NotConfigured` handling
- Registry write failures
- Post-restore verification failures

#### Lesson Learned

When an implementation replaces a planned placeholder, its tests must be reviewed as part of the same change. A failing obsolete test can indicate successful implementation progress rather than a code regression.

---

### Hermes.Common v0.1.0

#### Objective

Create a shared technical utility module so workstation modules do not independently reimplement logging, environment validation, Registry operations, JSON serialization, and Windows shell handling.

#### Public API

The initial release exports 14 commands.

Logging:

- `Write-HermesLog`
- `Write-HermesSuccess`
- `Write-HermesWarning`
- `Write-HermesError`

Validation:

- `Test-HermesAdministrator`
- `Test-HermesOperatingSystem`
- `Test-HermesPowerShell`

Registry:

- `Test-HermesRegistryPath`
- `Get-HermesRegistryValue`
- `Set-HermesRegistryValue`
- `Remove-HermesRegistryValue`

JSON and Windows shell:

- `Export-HermesJson`
- `Import-HermesJson`
- `Restart-HermesExplorer`

#### Engineering Decisions

##### Separate Shared Mechanics from Module Policy

`Hermes.Common` owns reusable technical mechanics. It does not define desired Explorer, Taskbar, Windows, Git, Terminal, or VS Code settings.

This boundary prevents the common module from becoming an unstructured collection of unrelated configuration policy.

##### Preserve Broad PowerShell Compatibility

The module manifest targets Windows PowerShell 5.1 and declares compatibility with Desktop and Core editions. Project Hermes continues to use PowerShell 7+ as its primary development shell, while the common helper layer avoids unnecessary incompatibility with a clean Windows installation.

##### Require Safe Mutation Patterns

State-changing helpers use `SupportsShouldProcess` and support `-WhatIf` and `-Confirm`.

Registry writes are idempotent and return structured objects distinguishing:

- A value that already matched
- A proposed `-WhatIf` operation
- A successfully applied operation

##### Keep Error Ownership Clear

`Write-HermesError` records an error-level message without terminating execution. Callers decide whether a condition should throw, continue, warn, or be reported in a summary.

#### Validation Evidence

The module passed:

- Manifest validation
- Clean module import
- Exact export validation for all 14 public commands
- Comment-based help validation
- Logging and UTF-8 file output tests
- PowerShell, platform, and administrator validation tests
- JSON read, write, overwrite, malformed-input, and `-WhatIf` tests
- Temporary HKCU Registry create, read, update, idempotency, removal, and `-WhatIf` tests
- Explorer restart `-WhatIf` tests without restarting the active shell

Final result:

```text
Tests Passed: 48
Tests Failed: 0
Tests Skipped: 0
```

#### Problem Encountered: Pester Test Isolation

The first complete Pester run produced:

```text
Tests Passed: 43
Tests Failed: 5
```

All five failures occurred in JSON tests because Pester 6 reused the same `$TestDrive` path across test cases. The first test created the JSON file, and later tests correctly encountered overwrite protection.

#### Corrective Action

Each JSON test now receives a unique GUID-based file path. No production module change was required.

The corrected suite passed all 48 tests.

#### Lesson Learned

Tests must isolate filesystem state explicitly rather than assuming the test runner removes artifacts between individual cases. A repeated failure pattern should be diagnosed at the shared fixture level before changing production code.

---

### Hermes.Taskbar

#### Objective

Implement selected Windows 11 taskbar settings using the lifecycle established by `Hermes.Explorer`.

#### Managed Scope

- Alignment
- Search presentation
- Task View visibility
- Widgets
- Copilot where supported
- Auto-hide
- Clock seconds where supported

#### Work Completed

- Implemented the six-command workstation lifecycle for discovery, validation, compliance testing, backup, configuration, and restoration.
- Integrated standardized backup storage through `Hermes.Core`.
- Integrated Registry access and Explorer restart handling through `Hermes.Common`.
- Added conservative handling for unsupported alignment, Search, and auto-hide values.
- Added idempotent apply and restore behavior.
- Added automatic safety backups before mutation unless explicitly skipped.
- Added `ShouldProcess`, `-WhatIf`, and `-Confirm` behavior for state-changing commands.
- Added contextual Registry failure reporting and independent post-change verification.
- Added version 2.0 Taskbar backup metadata containing canonical settings and Base64-encoded raw auto-hide data.
- Added exact restoration of previously unconfigured Registry values.
- Preserved compatibility with legacy backups that do not contain raw auto-hide metadata.
- Completed module documentation and comprehensive Pester coverage.

#### Validation

The completed module passed:

- `Test-ModuleManifest`
- Module removal and clean import
- Public command export inspection
- Comment-based help validation
- Configuration model and alias validation
- Registry mapping tests
- Compliance and difference reporting tests
- Backup metadata and custom backup-directory tests
- Apply, idempotency, `-WhatIf`, and error-path tests
- Exact restore, legacy restore, safety backup, and verification tests

Final Pester result:

```text
Tests Passed: 48
Tests Failed: 0
```

#### Problems Encountered

The expanded test suite exposed unsupported auto-hide bytes being silently interpreted as disabled and a compliance test fixture containing two differences while expecting one. A later restore test also treated `NotConfigured` as non-restorable even though exact restoration requires removing the managed Registry value.

#### Corrective Action

Unsupported auto-hide data is now reported as `Unknown`. Difference assertions were corrected to match the complete desired state. Restore validation now accepts `NotConfigured` as an intentional restorable state and rejects backups only when no supported or removable Taskbar state exists.

#### Engineering Decision

Taskbar backups store both a canonical configuration model and raw auto-hide Registry data. The canonical model supports readable validation and legacy compatibility; raw data permits exact restoration of the binary taskbar state without lossy interpretation.

#### Lesson Learned

Configuration backup formats must distinguish a setting that is absent, a supported configured value, and an unsupported value. Treating absence as a default can prevent exact restoration and conceal drift.

---

### Repository Documentation Synchronization

#### Work Completed

- Updated the root README for the v0.5.0 workstation milestone.
- Documented Windows 11 Home as the primary platform.
- Added current module status and architecture.
- Documented generated-data isolation and security considerations.
- Updated `CHANGELOG.md` with current work under `Unreleased`.
- Preserved v0.2.0, v0.3.1, and v0.4.0 tagged history.
- Standardized the `Hermes.Common` documentation filename as `README.md`.

#### Lesson Learned

Documentation drift became visible when the root README continued to present v0.4.0 as the current state after v0.5.0 work had begun. Repository documentation must be synchronized as a normal completion gate for each implementation milestone.

---

### Next Steps

1. Review whether `Hermes.Explorer` should adopt the proven `Hermes.Common` integration pattern.
2. Finalize the responsibility boundary between `Hermes.Common` and the existing core infrastructure.
3. Select and implement the next v0.5.0 workstation module.
4. Add profile-driven desired state after the component module contracts stabilize.
5. Perform an integrated v0.5.0 validation pass before merging into `main`.

---

## v0.4.0 — Validation Framework

**Status:** Complete  
**Development Branch:** `feature/v0.4-validation`  
**Completed:** July 19, 2026

### Objective

Establish a reliable validation framework capable of confirming that a workstation is prepared before deployment or configuration tasks execute.

The validator provides early detection of missing tools, repository configuration issues, and unsupported environments, reducing the likelihood of failures later in the provisioning process.

### Features Added

The centralized environment validator verifies:

- PowerShell
- Git
- GitHub CLI
- Visual Studio Code
- WinGet
- Repository directory structure
- Git repository initialization
- Git remote configuration

### Repository Standards

Added and refined repository-wide standards through:

- `.gitattributes`
- Consistent line-ending handling
- Repository structure validation
- Git and remote validation

### Validation Result

Successful execution returned:

```text
Passed:   12
Warnings: 0
Failed:   0
```

### Problems Encountered

#### PowerShell Execution Policy

Windows initially prevented unsigned script execution because the effective execution policy was `Restricted`.

Testing used a temporary process-level exception:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

This allowed validation without permanently weakening the machine-wide execution policy.

#### Repository Cleanup

A duplicate `gitignore(1)` file was identified and removed.

### Lessons Learned

- Validate prerequisites before deployment.
- Keep validation logic centralized and extensible.
- Prefer temporary, process-scoped execution-policy changes during local development.
- Maintain repository standards throughout implementation rather than deferring cleanup.

### Outcome

Version 0.4.0 established the validation foundation required for the v0.5.0 workstation framework.

---

## Journal Maintenance Standard

Future entries should record:

- Milestone and branch
- Objective
- Work completed
- Significant engineering decisions
- Validation evidence
- Problems encountered
- Corrective action
- Lessons learned
- Remaining work

Entries should describe implementation truthfully and must not mark a module or milestone complete before its required validation passes.
