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
| `Hermes.Desktop` lifecycle | Complete and tested |
| `Hermes.PowerShell` managed profile lifecycle | Complete and tested |
| `Hermes.Terminal` lifecycle | Complete and tested |
| `Hermes.Git` lifecycle | Complete and tested |
| `Hermes.VSCode` lifecycle | Complete and tested |
| `Hermes.PowerToys` lifecycle | Complete and tested |
| `Hermes.Winget` package profiles | Complete and tested |
| Component desired-state profiles | Complete and tested |
| Unified workstation profile | Complete and tested |
| v0.5.0 integration validation | Complete — 314 tests passed |

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

The complete Taskbar Pester suite currently passes **50 tests with no failures**.

The initial reproducible Windows Home desired state is stored in [`configs/windows/hermes-taskbar-base.psd1`](configs/windows/hermes-taskbar-base.psd1) and is validated by the Taskbar test suite. Copilot remains unmanaged because its policy key may reject user-level writes.

Hermes manages the native Windows taskbar state. Windhawk and similar shell tools
are treated as an optional visual-authority layer because they can override the
rendered taskbar without changing the native settings that Hermes validates.

Documentation: [`modules/workstation/taskbar/README.md`](modules/workstation/taskbar/README.md)

### Hermes.Windows

`Hermes.Windows` v0.5.0 manages application theme, system theme, transparency, and accent color on title bars through the standard Hermes lifecycle. It supports partial desired-state configurations, exact backup and restoration of configured or absent Registry values, independent verification, and an explicitly optional Explorer restart.

The initial reproducible desired state is stored in [`configs/windows/hermes-visual-base.psd1`](configs/windows/hermes-visual-base.psd1) and can be loaded safely with `Import-PowerShellDataFile`.

The complete Windows Pester suite currently passes **34 tests with no failures**.

Documentation: [`modules/workstation/windows/README.md`](modules/workstation/windows/README.md)

### Hermes.Desktop

`Hermes.Desktop` v0.5.0 manages the native Windows wallpaper path, wallpaper
fit mode, and desktop-icon visibility. It follows the standard Hermes lifecycle
with partial desired state, safety backups, `-WhatIf`, post-change verification,
and exact Registry restoration.

Adobe Creative Cloud and other design applications are asset-authoring tools,
not runtime dependencies. Exported wallpaper assets remain replaceable inputs to
the native Desktop configuration.

The complete `Hermes.Desktop` Pester suite passes **25 tests with no failures**.

The initial portable Desktop profile is stored in
[`configs/windows/hermes-desktop-base.psd1`](configs/windows/hermes-desktop-base.psd1)
and references the version-controlled wallpaper through a repository-relative path.

Documentation: [`modules/workstation/desktop/README.md`](modules/workstation/desktop/README.md)

### Hermes.PowerShell

`Hermes.PowerShell` v0.5.0 safely manages a clearly marked Project Hermes block
inside the current user's all-hosts PowerShell profile. It preserves unrelated
profile content, backs up the complete file before mutation, supports `-WhatIf`,
and restores the exact prior bytes or removes a profile that did not previously
exist.

The initial profile automatically imports the completed Hermes modules in each
new PowerShell 7 session, eliminating repeated manual imports during development.
The complete suite passes **15 tests with no failures**. Live validation also
confirmed that the managed profile imports the selected Hermes modules in a fresh
PowerShell 7 session outside the repository directory.

Documentation: [`modules/workstation/powershell/README.md`](modules/workstation/powershell/README.md)

### Hermes.Terminal

`Hermes.Terminal` v0.5.0 manages the Windows Terminal application theme,
default color scheme, font, opacity, acrylic material, cursor shape, and complete
Project Hermes color palette. It preserves unrelated profiles, actions, schemes,
and settings while backing up the exact original `settings.json` bytes.

The portable baseline is stored in
[`configs/terminal/hermes-terminal-base.psd1`](configs/terminal/hermes-terminal-base.psd1).
The module supports Store, Preview, unpackaged, and explicitly supplied Terminal
settings paths. Its complete Pester suite passes **14 tests with no failures**, and
the profile has been applied and independently verified on the development workstation.

Documentation: [`modules/workstation/terminal/README.md`](modules/workstation/terminal/README.md)

### Hermes.Git

`Hermes.Git` v0.5.0 manages selected user-level Git defaults for new branch
naming, Windows line endings, fetch pruning, pull behavior, automatic upstream
setup, and Git Credential Manager selection. It backs up the prior existence and
value of every managed key and restores missing values by removing only those keys.

The module deliberately excludes Git identity, credentials, signing configuration,
aliases, conditional includes, repository-local settings, and system configuration.
The portable baseline is stored in
[`configs/git/hermes-git-base.psd1`](configs/git/hermes-git-base.psd1).

The complete Pester suite passes **16 tests with no failures**. Live validation
confirmed safe application, independent compliance, idempotency, preserved user
identity, and an unchanged Project Hermes GitHub remote.

Documentation: [`modules/workstation/git/README.md`](modules/workstation/git/README.md)

### Hermes.VSCode

`Hermes.VSCode` v0.5.0 manages a selected set of Visual Studio Code user
settings while preserving unrelated JSON and JSONC configuration. The module
supports discovery, validation, compliance testing, exact-byte backup, safe
application, verification, restoration, `-WhatIf`, and idempotent execution.

The portable baseline is stored in
[`configs/vscode/hermes-vscode-base.psd1`](configs/vscode/hermes-vscode-base.psd1).
Its complete Pester suite passes **14 tests with no failures**, and live validation
confirmed the applied configuration and automatic module loading in a fresh shell.

Documentation: [`modules/workstation/vscode/README.md`](modules/workstation/vscode/README.md)

### Hermes.PowerToys

`Hermes.PowerToys` v0.5.0 manages approved global settings and selected feature
states while preserving every unmanaged PowerToys setting. It supports exact-byte
backup and restoration, safe preview, post-change verification, and idempotency.

The portable baseline is stored in
[`configs/powertoys/hermes-powertoys-base.psd1`](configs/powertoys/hermes-powertoys-base.psd1).
Its complete Pester suite passes **14 tests with no failures**, and the live
PowerToys v0.100.2 configuration is compliant.

Documentation: [`modules/workstation/powertoys/README.md`](modules/workstation/powertoys/README.md)

### Hermes.Winget

`Hermes.Winget` v0.5.0 defines explicit Core and Customization package profiles,
audits installed state, installs only missing approved packages, exports local JSON
inventory, and reports upgrades without applying them. It deliberately does not
uninstall software or perform blanket upgrades.

The approved package baseline is stored in
[`configs/winget/hermes-winget-base.psd1`](configs/winget/hermes-winget-base.psd1).
Its complete Pester suite passes **16 tests with no failures**. Live validation
confirmed all nine approved packages are installed, `-WhatIf` proposes no changes,
and the module loads from the managed PowerShell profile.

Documentation: [`modules/workstation/winget/README.md`](modules/workstation/winget/README.md)

### Unified Workstation Profile

The schema-versioned base workstation profile ties all ten configurable components
to their owning module manifests and desired-state files without duplicating policy.
It defines supported platform metadata, execution order, enabled state, required
versus optional components, and portable repository-relative paths.

The profile is stored in
[`configs/profiles/hermes-workstation-base.psd1`](configs/profiles/hermes-workstation-base.psd1),
with its contract documented in
[`docs/reference/workstation-profile-format.md`](docs/reference/workstation-profile-format.md).
Integration tests validate every referenced manifest and configuration through the
owning module's public validator.

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

Run the complete integrated suite:

```powershell
Invoke-Pester `
    -Path @(
        '.\modules'
        '.\tests'
    ) `
    -Output Detailed
```

The current v0.5.0 feature branch passes **314 tests with no failures** across
13 test files.

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
- Visual Studio Code configuration (complete and tested)
- Desktop configuration
- PowerToys configuration (complete and tested)
- WinGet package profiles (complete and tested)
- Unified workstation profile (complete and tested)
- Integrated module and profile validation (314 tests passed)
- Final release closeout

### Future Milestones

- Developer environment provisioning
- WSL and Docker automation
- Rainmeter and Windhawk integration
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
| [`docs/implementation/v0.5-installation-and-usage.md`](docs/implementation/v0.5-installation-and-usage.md) | Documents supported v0.5 installation, preview, apply, validation, and recovery workflows. |

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
