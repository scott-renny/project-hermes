# Changelog

All notable changes to Project Hermes are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Project Hermes uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where applicable.

## [Unreleased]

### Added

- `Hermes.Common` v0.1.0 shared utility module.
- Standardized logging with console and UTF-8 file output.
- Administrator, operating-system, and PowerShell version validation helpers.
- Safe Registry path, read, write, and removal helpers.
- Idempotent Registry writes with structured operation results.
- UTF-8 JSON import and export helpers.
- Windows Explorer shell restart helper.
- `ShouldProcess`, `-WhatIf`, and `-Confirm` support for shared state-changing operations.
- Complete comment-based help for all `Hermes.Common` public commands.
- Module-level `Hermes.Common` documentation.
- Comprehensive `Hermes.Common` Pester suite with 48 passing tests.
- Completed `Hermes.Explorer` restore lifecycle with backup validation, safety backups, idempotency, `-WhatIf`, and post-restore verification.
- Expanded `Hermes.Explorer` Pester coverage for the completed restore workflow.
- `Hermes.Taskbar` v0.5.0 with current-state discovery, configuration validation, compliance testing, backup, apply, verification, and restore commands.
- Taskbar management for alignment, Search presentation, Task View, Widgets, Copilot policy, auto-hide, and clock seconds where supported.
- Version 2.0 Taskbar backup metadata with raw binary auto-hide state preserved for exact restoration.
- Restoration of previously unconfigured Registry values by removing only the corresponding managed value.
- Legacy Taskbar backup compatibility when version 2.0 raw auto-hide metadata is unavailable.
- Independent post-apply and post-restore verification.
- Complete `Hermes.Taskbar` documentation and a comprehensive Pester suite with 48 passing tests.
- `Hermes.Windows` v0.5.0 with discovery, validation, compliance testing, backup, apply, verification, and restore commands.
- Management of application theme, system theme, transparency, and accent color on title bars.
- Partial Windows desired-state configurations so callers can manage selected settings without overwriting the others.
- Version 1.0 Windows backup metadata preserving exact Registry existence and values.
- Exact Windows personalization restoration with legacy canonical-backup compatibility.
- Complete `Hermes.Windows` documentation and a Pester suite with 32 passing tests.

### Changed

- Updated the root README for the active v0.5.0 workstation architecture.
- Documented Windows 11 Home as the primary Project Hermes platform.
- Expanded repository documentation for module responsibilities, safety, validation, generated runtime data, and current milestone status.
- Standardized the `Hermes.Common` module documentation filename as `README.md`.
- Advanced `Hermes.Explorer` to module version 0.4.0.
- Integrated `Hermes.Taskbar` with `Hermes.Core` for standardized backups and `Hermes.Common` for Registry and Explorer operations.
- Classified unsupported auto-hide binary data as `Unknown` instead of silently treating it as disabled.
- Refactored `Hermes.Explorer` to use `Hermes.Common` for all managed Registry reads, writes, and removals while retaining `Hermes.Core` backup services.
- Standardized the one-way shared dependency pattern across the completed Explorer and Taskbar workstation modules.
- Expanded the Explorer module documentation with dependencies, configuration examples, validation procedures, safety behavior, and restore guidance.
- Defined the stable responsibility and dependency boundary between `Hermes.Core`, `Hermes.Common`, and component modules.
- Aligned the `Hermes.Explorer` manifest with its mandatory PowerShell 7.0 `Hermes.Core` dependency.
- Replaced the minimal `Hermes.Core` README with complete contract, usage, dependency, and validation documentation.

### Documentation

- Added `docs/reference/shared-module-architecture.md` as the authoritative shared-module architecture decision.

### Fixed

- Replaced the obsolete `Hermes.Explorer` restore placeholder test with validation of the completed implementation.
- Corrected test isolation in `Hermes.Common` JSON tests for Pester 6.
- Prevented generated logs, baselines, backups, summaries, and state files from being tracked by Git.
- Removed temporary documentation backups and the dated Taskbar backup directory from the source tree.
- Corrected Taskbar compliance difference reporting and unsupported auto-hide state handling.
- Corrected restore validation so backups containing only unsupported values are rejected while `NotConfigured` values remain restorable.
- Corrected the Hermes.Windows Pester 6 discovery and execution import lifecycle.
- Prevented PowerShell pipeline unrolling from converting one-item Windows configuration property collections into scalars.
- Prevented `Hermes.Core` from generating duplicated `Hermes.Hermes.*` backup filename prefixes for canonically named component modules.

### Security

- Excluded workstation-specific runtime output from version control by default.
- Added explicit documentation warning against committing credentials, private keys, tokens, network details, or unreviewed machine inventories.

## [0.4.0] - 2026-07-19

### Added

- Centralized workstation environment validation framework.
- PowerShell validation.
- Git validation.
- GitHub CLI validation.
- Visual Studio Code validation.
- WinGet validation.
- Repository directory validation.
- Git repository and remote configuration validation.
- `.gitattributes` for consistent repository formatting and line-ending behavior.

### Changed

- Improved repository engineering standards.
- Established a reusable validation architecture.
- Standardized repository line-ending handling.

### Fixed

- Removed the duplicate `gitignore(1)` file.
- Improved repository consistency before workstation module development.

## [0.3.1] - 2026-07-19

### Added

- Safe Windows Explorer configuration workflow.
- Explorer configuration backup support.
- Explorer configuration validation and verification.
- Initial Explorer Pester coverage.

### Changed

- Refined the workstation module architecture around safe configuration management.

## [0.2.0] - 2026-07-19

### Added

- `Hermes.Core` shared infrastructure.
- Modular initialization workflow.
- Portable repository-root discovery.
- Structured logging, execution state, and summary reporting.
- Administrator-aware inventory behavior.
- Resumable execution support.
- Corrected installed-program inventory.
- Winget timeout and skip handling.

## [0.1.0] - 2026-07-19

### Added

- Initial Project Hermes repository foundation.
- Bootstrap framework.
- Windows workstation baseline collection.
- Core tool installation workflow.
- Initial project documentation and repository standards.

[Unreleased]: https://github.com/scott-renny/project-hermes/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.4.0
[0.3.1]: https://github.com/scott-renny/project-hermes/releases/tag/v0.3.1
[0.2.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.2.0
