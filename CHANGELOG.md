# Changelog

All notable changes to Project Hermes are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Project Hermes uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where applicable.

## [Unreleased]

## [v1.0.1] — 2026-08-09

### Changed

- Synchronized public documentation and governance metadata with the stable release.
- Replaced machine-specific paths and host aliases in portable examples.
- Strengthened exclusions for local launcher settings, local configuration, and VPN exports.
- Updated security reporting guidance and repository architecture summaries.

### Validation

- Confirmed the sensitive-pattern scan returns no private hostnames, internal addresses, or personal paths.
- Validated the complete repository with 381 passing tests and no failures.
- Confirmed the patch does not change supported workstation automation behavior.

## [v1.0.0] — 2026-08-08

### Stable

- Declared the supported Project Hermes workstation lifecycle stable.
- Validated 381 Pester tests with no failures.
- Validated all 15 PowerShell module manifests and repository PowerShell parsing.
- Confirmed all 11 canonical workstation components are compliant.
- Confirmed orchestration preflight, recovery readiness, sanitized reporting evidence, and documented restore coverage.
- Recorded the completed WireGuard installation and Home and Untrusted tunnel profiles.
- Completed the release documentation, security/privacy review evidence, and public workflow audit.
## [0.9.0] - 2026-08-08

### Added

- `Hermes.Orchestration` v0.9.0 as the unified workstation entry point.
- Ordered plans, preflight validation, audit and selective apply modes, persistent run state, bounded resume, and JSON/Markdown reports.
- Explicit component exclusions that remain visible as `Skipped` results.
- Elevation-awareness metadata for preflight checks and completed runs.

### Changed

- Added independent compliant, drifted, planned, skipped, and failure summaries.
- Updated resume behavior so intentionally skipped components are not repeated.
- Advanced the active roadmap milestone to v1.0.0 stable reproducible workstation release.

### Safety

- Preserved explicit apply behavior and `WhatIf` previews without state-file writes.
- Kept ordinary user-scope configuration available without unnecessary administrator mode.

### Validation

- Validated the complete repository with 381 passing Pester tests and no failures, skips, inconclusive results, or tests left unrun.
- Completed whitespace validation and focused orchestration validation with 24 passing tests.

## [0.8.0] - 2026-08-08

### Added

- `Hermes.Maintenance` v0.8.0 for unified workstation audits, backup-health evaluation, and consolidated maintenance reporting.
- JSON and Markdown maintenance report export with sanitized public samples.
- Recovery-readiness coverage for portable backup round trips and every supported workstation restore command.
- Explicit operational references to the COC engineering runbook repository.

### Changed

- Aligned portable desired-state files with the completed v0.7 visual environment.
- Advanced the active roadmap milestone to v0.9.0 integrated orchestration and release-candidate preparation.

### Safety

- Kept repair, restore, retention cleanup, and other destructive actions explicit and user controlled.
- Excluded machine identity, local user paths, and secrets from published sample reports.

### Validation

- Validated the complete repository with 357 passing Pester tests and no failures, skips, inconclusive results, or tests left unrun.
- Completed whitespace validation and recovery-evidence review.
## [0.7.0] - 2026-08-08

### Added

- Original Project Hermes gothic command-center wallpaper.
- Rainmeter clock, application launcher, editable notes, and system-monitoring sidebar skins.
- Shared Rainmeter visual resources and a repeatable installation script.
- Guarded Explorer and PowerShell theme integration scripts, including Windows Terminal color-scheme support.
- v0.7 visual-environment implementation and operating documentation.

### Changed

- Advanced the active roadmap milestone to v0.8.0 recovery, maintenance, and reporting.
- Refined the visual milestone to preserve optional tooling and explicit compatibility boundaries.

### Validation

- Validated the merged `main` state with 328 passing Pester tests and no failures.
- Confirmed clean PowerShell parsing, whitespace validation, and review for secrets and personal machine paths.
- Visually validated the desktop, taskbar, Start menu, Explorer, PowerShell, Quick Settings, notifications, and context menus.
## [0.6.0] - 2026-08-08

### Added

- `Hermes.Developer` v0.6.0 with required-tool inventory, previewable WinGet and VS Code extension provisioning, SSH-agent and host-alias compliance, JSON inventory export, and bounded Remote SSH connectivity testing.
- Portable developer baseline covering Git, GitHub CLI, PowerShell 7, Visual Studio Code, OpenSSH, required VS Code extensions, the `hermes-remote-host` alias, and non-required runtime capability reporting.
- Developer-environment integration in the unified workstation profile and managed PowerShell startup profile.
- Explicit ownership boundary keeping Ubuntu COC containers, secrets, backups, network policy, and repositories outside workstation provisioning.
- Full profile-isolated repository validation with 328 passing tests and no failures.

### Network Boundary

- Validated hardened key-based Remote SSH to `hermes-remote-host` on the trusted home network.
- Deferred VPN configuration and untrusted-network validation in v0.6.0 without claiming off-network readiness; WireGuard configuration was completed for v1.0.0.

### Added

- Supported v0.5.0 installation-and-usage guide covering prerequisites, complete validation, component preview and application, managed PowerShell initialization, WinGet safety, generated data, and recovery boundaries.
- v0.5.0 release-candidate overview and release gate in `RELEASES.md`.

- Schema-versioned unified workstation profile spanning ten configurable components through portable module and configuration references.
- Version-controlled Explorer desired-state baseline and dictionary-compatible Explorer configuration validation.
- Workstation profile-format reference documentation and nine integration tests covering schema, platform, ordering, paths, manifests, and component validation.
- Canonical integrated validation across module and root integration suites with 314 passing tests and no failures.

- `Hermes.VSCode` v0.5.0 with preserved JSON/JSONC settings, exact-byte backup and restoration, safe apply, verification, and 14 passing tests.
- `Hermes.PowerToys` v0.5.0 with preservation of unmanaged settings, selected feature-state management, exact-byte recovery, live v0.100.2 compliance, and 14 passing tests.
- `Hermes.Winget` v0.5.0 with explicit Core and Customization package profiles, installed-state auditing, selective installation, JSON inventory export, read-only upgrade reporting, and 16 passing tests.
- Live WinGet validation confirming all nine approved packages are installed and compliant without unnecessary installation.
- Integrated v0.5.0 validation across 12 test files with 304 passing tests and no failures.

- `Hermes.Git` v0.5.0 with global-setting discovery, validation, compliance testing, backup, safe apply, verification, and exact managed-key restoration.
- Version-controlled Git baseline for default branch naming, line-ending behavior, fetch pruning, pull strategy, automatic upstream setup, and credential-helper selection.
- Complete `Hermes.Git` documentation and a Pester suite with 16 passing tests.
- Successful live application, idempotency validation, identity preservation, and repository remote verification.

- `Hermes.Terminal` v0.5.0 with settings discovery, configuration validation, compliance testing, exact-byte backup, safe apply, verification, and exact restoration.
- Version-controlled `Project Hermes` Windows Terminal color scheme and visual baseline.
- Preservation of unrelated Terminal profiles, actions, schemes, themes, and application settings.
- Store, Preview, unpackaged, and explicit Windows Terminal settings-path support.
- Complete `Hermes.Terminal` documentation and a Pester suite with 14 passing tests.
- Successful live backup, application, and independent compliance verification of the Hermes Terminal baseline.

- `Hermes.PowerShell` v0.5.0 with safe managed-block installation, validation, backup, exact restore, and automatic module initialization.
- Version-controlled initial PowerShell module-loading profile.
- Complete `Hermes.PowerShell` documentation and a Pester suite with 15 passing tests.
- Successful live profile installation and automatic module-import validation in a fresh PowerShell 7 session.

- `Hermes.Desktop` v0.5.0 with native wallpaper path, wallpaper style, and desktop-icon visibility management.
- Desktop discovery, validation, compliance testing, backup, apply, verification, and exact restore commands.
- Complete `Hermes.Desktop` module documentation and a Pester suite with 25 passing tests.
- Version-controlled `configs/windows/hermes-desktop-base.psd1` profile and initial Hermes wallpaper concept.
- Automated validation that the Desktop profile exists, resolves its wallpaper asset, and remains compatible with `Hermes.Desktop`.
- Successful live application and independent verification of the initial Hermes Desktop wallpaper baseline.

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
- Complete `Hermes.Taskbar` documentation and a comprehensive Pester suite with 50 passing tests.
- `Hermes.Windows` v0.5.0 with discovery, validation, compliance testing, backup, apply, verification, and restore commands.
- Management of application theme, system theme, transparency, and accent color on title bars.
- Partial Windows desired-state configurations so callers can manage selected settings without overwriting the others.
- Version 1.0 Windows backup metadata preserving exact Registry existence and values.
- Exact Windows personalization restoration with legacy canonical-backup compatibility.
- Complete `Hermes.Windows` documentation and a Pester suite with 34 passing tests.
- Version-controlled `configs/windows/hermes-visual-base.psd1` profile for the initial dark Hermes appearance.
- Automated validation that the visual profile exists and remains compatible with `Hermes.Windows`.
- Version-controlled `configs/windows/hermes-taskbar-base.psd1` profile for the initial operations-focused Taskbar layout.
- Automated validation that the Taskbar profile remains a complete supported configuration.

### Changed

- Updated the Project Charter from planning status to active v0.5.0 release-candidate development.
- Recorded Hermes concept v1 as the initial lock-screen candidate for the future visual-integration milestone.

- Made the WinGet private-scope tests discovery-safe during complete clean-session Pester runs.
- Updated the canonical full-suite command to include both `modules` and root `tests`.

- Added `Hermes.VSCode`, `Hermes.PowerToys`, and `Hermes.Winget` to the managed PowerShell startup profile.
- Updated root project documentation to distinguish completed component profiles from the remaining unified workstation profile and release-closeout work.

- Added `Hermes.Git` to the managed PowerShell startup profile.
- Consolidated `.gitignore` into one authoritative generated-data, temporary-file, editor, Windows, and credential exclusion policy.
- Standardized active configuration data under `configs/` and removed the obsolete singular `config/` prototype.
- Added `Hermes.Terminal` to the managed PowerShell startup profile.
- Normalized Windows Terminal scheme properties to the canonical lower-camel-case JSON schema.
- Added portable repository-relative wallpaper resolution to `Hermes.Desktop` while retaining absolute-path support.

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
- Limited the initial Taskbar profile to Windows Home-compatible user settings and left the protected Copilot policy unmanaged.
- Added automatic Taskbar backup-path context to Registry write failures.

### Documentation

- Removed the stale duplicate Taskbar README and retained the standard module-level `README.md`.
- Added `docs/reference/shared-module-architecture.md` as the authoritative shared-module architecture decision.
- Documented the boundary between native Hermes Taskbar state and optional Windhawk visual overrides.

### Fixed

- Removed redundant module placeholders, an unused configuration utility, and empty or non-operational workstation scripts that implied unsupported orchestration behavior.
- Made PowerShell profile parent-directory creation terminating and independently verified before writing the managed profile.
- Routed PowerShell profile writes and byte-exact restoration through the PowerShell filesystem provider for OneDrive-backed profile compatibility.
- Corrected zero-byte PowerShell profile handling so empty existing files produce valid state and backups instead of null-value cascades.
- Added defensive profile-text normalization at every managed-block, compliance, backup, and installation boundary.
- Isolated PowerShell profile lifecycle tests after adding zero-byte profile coverage.

- Prevented PowerShell scalar unrolling from breaking single-match Hermes.Desktop configuration normalization under strict mode.

- Replaced the obsolete `Hermes.Explorer` restore placeholder test with validation of the completed implementation.
- Corrected test isolation in `Hermes.Common` JSON tests for Pester 6.
- Prevented generated logs, baselines, backups, summaries, and state files from being tracked by Git.
- Removed temporary documentation backups and the dated Taskbar backup directory from the source tree.
- Corrected Taskbar compliance difference reporting and unsupported auto-hide state handling.
- Corrected restore validation so backups containing only unsupported values are rejected while `NotConfigured` values remain restorable.
- Corrected the Hermes.Windows Pester 6 discovery and execution import lifecycle.
- Prevented PowerShell pipeline unrolling from converting one-item Windows configuration property collections into scalars.
- Prevented `Hermes.Core` from generating duplicated `Hermes.Hermes.*` backup filename prefixes for canonically named component modules.
- Prevented the initial Taskbar profile from failing on access-denied writes to the Windows Copilot policy key.
- Prevented the internal Explorer restart result from leaking into the public `Set-HermesTaskbarSettings` result stream.

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

[Unreleased]: https://github.com/scott-renny/project-hermes/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.8.0
[0.7.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.7.0
[0.6.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.6.0
[0.5.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.5.0
[0.4.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.4.0
[0.3.1]: https://github.com/scott-renny/project-hermes/releases/tag/v0.3.1
[0.2.0]: https://github.com/scott-renny/project-hermes/releases/tag/v0.2.0
