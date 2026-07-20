# Project Hermes

<h1 align="center">Project Hermes</h1>

<p align="center">
<b>Windows Engineering Workstation Automation Framework</b>
</p>

<p align="center">

![Status](https://img.shields.io/badge/Status-Active%20Development-orange?style=for-the-badge)
![Milestone](https://img.shields.io/badge/Milestone-v0.5.0%20Workstation-0078D6?style=for-the-badge)
![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-11%20Home-0078D6?style=for-the-badge&logo=windows11&logoColor=white)
![License](https://img.shields.io/github/license/scott-renny/project-hermes?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/scott-renny/project-hermes?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/scott-renny/project-hermes?style=for-the-badge)

</p>

---

## Overview

Project Hermes is a modular PowerShell framework for provisioning, configuring, validating, backing up, restoring, and maintaining Windows engineering workstations.

Hermes replaces manual workstation setup with documented, repeatable, and testable configuration workflows. Its modules support software engineering, cybersecurity work, homelab administration, and infrastructure operations while preserving clear rollback paths and validation evidence.

The current development milestone, **v0.5.0 Workstation**, is establishing a consistent lifecycle for Windows configuration modules:

```text
Get current state
        ↓
Validate configuration
        ↓
Back up current state
        ↓
Apply desired state
        ↓
Verify applied state
        ↓
Restore when required
```

---

## Current Status

| Area | Status |
|---|---|
| Stable release | v0.4.0 — Validation Framework |
| Development milestone | v0.5.0 — Workstation Framework |
| Development branch | `feature/v0.5-workstation` |
| Primary platform | Windows 11 Home |
| Primary shell | PowerShell 7+ |
| License | MIT |

### v0.5.0 Progress

| Component | Status |
|---|---|
| Repository cleanup and generated-data exclusions | Complete |
| `Hermes.Explorer` lifecycle | Complete and tested |
| `Hermes.Common` shared utilities | Complete and tested |
| `Hermes.Taskbar` lifecycle | Complete and tested |
| `Hermes.Windows` personalization lifecycle | Complete and tested |
| Remaining workstation modules | Planned |
| v0.5.0 integration validation | Planned |

`Hermes.Common` v0.1.0 and `Hermes.Taskbar` v0.5.0 each pass **48 Pester tests with no failures**.

---

## Project Objectives

- Provision a consistent Windows engineering workstation.
- Replace manual configuration with version-controlled automation.
- Make state-changing operations safe, idempotent, and testable.
- Back up configuration before applying changes.
- Verify the resulting state after each operation.
- Provide documented restore paths.
- Separate reusable framework helpers from component-specific policy.
- Maintain complete engineering documentation and validation evidence.

---

## Quick Start

Clone the repository:

```powershell
git clone https://github.com/scott-renny/project-hermes.git
cd project-hermes
```

Validate the local environment:

```powershell
.\scripts\diagnostics\Test-HermesEnvironment.ps1 -Detailed
```

Import the shared utility module:

```powershell
Import-Module `
    .\modules\common\Hermes.Common.psd1 `
    -Force
```

List its commands:

```powershell
Get-Command -Module Hermes.Common
```

Run its tests:

```powershell
Invoke-Pester `
    -Path .\modules\common\tests `
    -Output Detailed
```

Project Hermes remains under active development. Review module documentation and use `-WhatIf` for supported state-changing commands before applying them.

---

## Architecture

Project Hermes separates orchestration, reusable framework helpers, component policy, configuration data, documentation, and generated runtime output.

```text
Project-Hermes/
├── configs/
│   ├── packages/
│   ├── powershell/
│   ├── rainmeter/
│   ├── terminal/
│   ├── vscode/
│   ├── windhawk/
│   └── windows/
├── docs/
│   ├── implementation/
│   ├── planning/
│   ├── reference/
│   └── screenshots/
├── exports/                  # Generated locally; ignored by Git
├── logs/                     # Generated locally; ignored by Git
├── modules/
│   ├── common/
│   ├── developer/
│   └── workstation/
├── scripts/
│   ├── automation/
│   ├── backups/
│   ├── bootstrap/
│   ├── diagnostics/
│   ├── maintenance/
│   └── modules/
├── themes/
├── README.md
├── BUILD_JOURNAL.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── ENGINEERING_STANDARD.md
├── LICENSE
├── PROJECT_CHARTER.md
├── RELEASES.md
├── ROADMAP.md
└── SECURITY.md
```

### Directory Responsibilities

| Directory | Responsibility |
|---|---|
| `modules/common` | Reusable technical helpers shared across Hermes modules. |
| `modules/core` | Repository-aware identity and standardized backup infrastructure. |
| `modules/workstation` | Windows workstation configuration policy and lifecycle modules. |
| `modules/developer` | Developer tooling and platform provisioning modules. |
| `scripts` | Executable orchestration, diagnostics, bootstrap, and maintenance entry points. |
| `configs` | Application and platform configuration files deployed by Hermes. |
| `docs` | Planning, implementation, reference, and visual documentation. |
| `exports` | Local backups, baselines, state, and summaries. |
| `logs` | Local execution and installation logs. |

Generated exports and logs remain local and are excluded from Git except for folder placeholders.

---

## Module Standards

Workstation configuration modules follow a consistent public lifecycle where applicable:

```text
Get-Hermes<Component>Settings
Test-Hermes<Component>Configuration
Test-Hermes<Component>Settings
Backup-Hermes<Component>Settings
Set-Hermes<Component>Settings
Restore-Hermes<Component>Settings
```

Each completed module is expected to provide:

- A valid PowerShell module manifest
- Explicit public command exports
- Complete comment-based help
- Input and configuration validation
- Idempotent configuration behavior
- Backup before mutation
- Post-change verification
- Restore support
- `ShouldProcess`, `-WhatIf`, and `-Confirm` where appropriate
- A module-specific README
- Pester coverage

Shared modules follow a peer dependency model: `Hermes.Core` owns repository-aware persistence and backup contracts, while `Hermes.Common` owns repository-independent technical helpers. Neither imports the other; component modules import only what they require. See [`docs/reference/shared-module-architecture.md`](docs/reference/shared-module-architecture.md).

---

## Current Modules

### Hermes.Common

`Hermes.Common` supplies shared technical helpers for:

- Standardized logging
- Administrator, operating-system, and PowerShell validation
- Safe Registry reads, writes, and removals
- UTF-8 JSON import and export
- Windows Explorer shell restart handling

Documentation: [`modules/common/README.md`](modules/common/README.md)

### Hermes.Explorer

`Hermes.Explorer` manages Windows Explorer settings through a validated lifecycle with backup, restore, idempotency, `-WhatIf`, and post-restore verification.

The module uses `Hermes.Core` for standardized backup services and `Hermes.Common` for all managed Registry reads, writes, and removals. This establishes the same one-way shared-dependency pattern used by `Hermes.Taskbar` without changing Explorer's public API.

Documentation: [`modules/workstation/explorer/README.md`](modules/workstation/explorer/README.md)

### Hermes.Taskbar

`Hermes.Taskbar` v0.5.0 manages selected Windows 11 taskbar settings through the standard Hermes lifecycle. It validates desired state, detects compliance, creates versioned backups, applies settings safely, verifies the result, and restores configured or previously unconfigured Registry state.

The module uses `Hermes.Core` for standardized backup storage and `Hermes.Common` for Registry operations and Windows Explorer restart handling. Its backup format preserves canonical settings and the raw binary taskbar auto-hide state for exact restoration while retaining compatibility with legacy backups.

The complete Taskbar Pester suite currently passes **48 tests with no failures**.

Documentation: [`modules/workstation/taskbar/README.md`](modules/workstation/taskbar/README.md)

### Hermes.Windows

`Hermes.Windows` v0.5.0 manages application theme, system theme, transparency, and accent color on title bars through the standard Hermes lifecycle. It supports partial desired-state configurations, exact backup and restoration of configured or absent Registry values, independent verification, and an explicitly optional Explorer restart.

The complete Windows Pester suite currently passes **32 tests with no failures**.

Documentation: [`modules/workstation/windows/README.md`](modules/workstation/windows/README.md)

---

## Validation

Validate a module manifest:

```powershell
Test-ModuleManifest `
    .\modules\common\Hermes.Common.psd1
```

Import a module and inspect its exports:

```powershell
Remove-Module Hermes.Common -Force -ErrorAction SilentlyContinue

Import-Module `
    .\modules\common\Hermes.Common.psd1 `
    -Force

Get-Command -Module Hermes.Common
```

Run a module test suite:

```powershell
Invoke-Pester `
    -Path .\modules\common\tests `
    -Output Detailed
```

No module is considered complete until its manifest, import, public exports, documentation, and Pester suite have been validated.

---

## Engineering Principles

- Documentation before and alongside implementation
- Function before appearance
- Modular architecture
- Least privilege
- Safe and reversible changes
- Idempotent execution
- Explicit validation
- Version-controlled configuration
- Generated-data isolation
- Incremental releases
- Complete files instead of undocumented manual edits

---

## Roadmap

### v0.4.0 — Validation Framework

Completed:

- Bootstrap framework
- Environment validation
- Repository standards
- Git and remote validation
- Core tool validation

### v0.5.0 — Workstation Framework

In progress:

- Shared common utilities
- Windows Explorer configuration
- Taskbar configuration (complete and tested)
- Windows personalization configuration (complete and tested)
- PowerShell profile deployment
- Windows Terminal configuration
- Git configuration
- Visual Studio Code configuration
- Desktop configuration
- Workstation profile integration

### Future Milestones

- Developer environment provisioning
- WSL and Docker automation
- PowerToys, Rainmeter, and Windhawk integration
- Backup, restore, repair, and drift detection
- Reporting and operational summaries
- Full workstation orchestration
- Stable v1.0.0 release

See [`ROADMAP.md`](ROADMAP.md) for the broader project execution plan.

---

## Documentation

| Document | Purpose |
|---|---|
| [`PROJECT_CHARTER.md`](PROJECT_CHARTER.md) | Defines project purpose, boundaries, governance, and success criteria. |
| [`ROADMAP.md`](ROADMAP.md) | Defines project phases and planned outcomes. |
| [`ENGINEERING_STANDARD.md`](ENGINEERING_STANDARD.md) | Defines engineering and documentation standards. |
| [`BUILD_JOURNAL.md`](BUILD_JOURNAL.md) | Records implementation history, decisions, and lessons learned. |
| [`CHANGELOG.md`](CHANGELOG.md) | Records release-focused changes. |
| [`RELEASES.md`](RELEASES.md) | Documents release history and release policy. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Defines contribution and review requirements. |
| [`SECURITY.md`](SECURITY.md) | Defines security and disclosure practices. |

---

## Security and Privacy

Project Hermes collects workstation state and can change user-level Windows configuration. Generated baselines, logs, backups, summaries, and state files may contain machine-specific information.

These files remain excluded from version control by default:

```text
logs/*
exports/backups/*
exports/baseline/*
exports/state/*
exports/summaries/*
```

Do not commit credentials, tokens, private keys, personal paths, network details, or unreviewed machine inventories.

Report security concerns according to [`SECURITY.md`](SECURITY.md).

---

## License

Project Hermes is released under the MIT License. See [`LICENSE`](LICENSE) for details.
