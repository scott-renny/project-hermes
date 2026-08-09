# Project Hermes Releases

This document provides a high-level overview of each Project Hermes release.

While the `CHANGELOG.md` contains a technical record of every change, this document focuses on the goals, major features, and overall progress of each release.

---

# Version History

| Version | Status | Summary |
|----------|--------|---------|
| v1.0.1 | ✅ Released | Public Release Sanitization |
| v1.0.0 | ✅ Released | Stable Reproducible Workstation |
| v0.9.0 | ✅ Released | Integrated Orchestration and Release Candidate |
| v0.8.0 | ✅ Released | Recovery, Maintenance, and Reporting |
| v0.7.0 | ✅ Released | Visual Environment and Productivity Integration |
| v0.6.0 | ✅ Released | Developer Environment Provisioning |
| v0.5.0 | ✅ Released | Workstation Framework |
| v0.4.0 | ✅ Released | Validation Framework |
| v0.3.0 | ✅ Released | Bootstrap Framework |

---

# v1.0.1 — Public Release Sanitization

**Status**

Released and tagged on `main`

**Release Date**

August 9, 2026

---

## Overview

Version 1.0.1 synchronizes the public repository with the stable v1 release. It
removes machine-specific paths and host aliases from portable examples, strengthens
local-configuration exclusions and security-reporting guidance, and updates public
release and governance documentation.

## Validation

- Sensitive-pattern scan returned no private hostnames, internal addresses, or personal paths.
- The complete repository suite passed 381 tests with no failures.
- Whitespace validation completed without errors.
- Workstation automation behavior is unchanged from v1.0.0.

---

# v1.0.0 — Stable Reproducible Workstation

**Status**

Released and tagged on `main`

**Release Date**

August 8, 2026

---

## Overview

Version 1.0.0 is the first stable release of the supported Windows 11 workstation
automation framework. It combines the complete workstation lifecycle, recovery and
maintenance evidence, and integrated orchestration behind documented and validated
public workflows.

## Validation

- Full Pester suite: **381 passed, 0 failed**.
- PowerShell parsing: no errors across modules, scripts, and tests.
- Module manifests: **15 valid, 0 invalid**.
- Canonical workstation audit: **11 of 11 components compliant**.
- Orchestration preflight and recovery readiness passed.

---

# v0.9.0 — Integrated Orchestration and Release Candidate

**Status**

Released and tagged on `main`

**Release Date**

August 8, 2026

---

## Overview

Version 0.9.0 combines the existing Project Hermes modules behind a single ordered
workstation orchestration layer. It supports preflight validation, auditing,
selective and previewable application, persistent run state, bounded resume, and
consolidated JSON and Markdown reporting.

## Highlights

- `Hermes.Orchestration` v0.9.0 with six documented public commands
- Ordered execution across all eleven workstation-profile components
- Explicit component inclusion and exclusion with visible `Skipped` results
- Elevation-aware preflight and execution reporting
- Separate execution-success and desired-state compliance summaries
- Resumable state that avoids repeating compliant, applied, or skipped work
- 381 passing Pester tests with no failures

## Safety Boundaries

- Apply mode remains explicit and supports `WhatIf`.
- Preview runs do not write orchestration state.
- User-scope configuration does not require an elevated shell.
- Components that may install machine-wide software identify that requirement and
  allow Windows to request approval only when a change is necessary.

## Release Result

The release-candidate orchestration workflow passed the complete repository suite,
including component ordering, exclusions, elevation awareness, reporting, resume,
maintenance, recovery, visual integration, and every workstation module contract.

---

# v0.8.0 — Recovery, Maintenance, and Reporting

**Status**

Released and tagged on `main`

**Release Date**

August 8, 2026

---

## Overview

Version 0.8.0 adds evidence-based workstation maintenance and recovery readiness.
It consolidates component drift, backup health, retention findings, and operational
references into portable JSON and Markdown reports while keeping repair and restore
actions explicit and user controlled.

## Highlights

- `Hermes.Maintenance` v0.8.0 with five documented public commands
- Unified audits across the selected workstation profile
- Backup health and retention-policy evaluation
- Structured JSON and Markdown maintenance reports
- Portable backup round-trip and restore-surface validation
- Sanitized sample reports covering every supported outcome
- 357 passing Pester tests with no failures

## Safety Boundaries

- Maintenance audits and reports do not automatically repair drift.
- Restore operations remain explicit, independently exported, and previewable where supported.
- Public samples exclude local paths, live workstation identity, and secrets.
- Destructive cleanup remains deferred to documented, user-controlled workflows.

## Release Result

The complete repository suite passed with 357 tests and no failures. Recovery-readiness
evidence verifies portable backups, explicit restore commands, `WhatIf` documentation,
and sanitized maintenance output suitable for public review.

---
# v0.7.0 — Visual Environment and Productivity Integration

**Status**

Released and tagged on `main`

**Release Date**

August 8, 2026

---

## Overview

Version 0.7.0 delivers the Project Hermes gothic command-center environment as an
optional, repository-controlled visual layer. It combines original wallpaper,
Rainmeter panels, and guarded shell-theme helpers without making the visual stack a
prerequisite for the underlying workstation framework.

## Highlights

- Original gothic command-center wallpaper and cohesive violet visual language
- Rainmeter clock, launcher, notes, and monitoring sidebars
- Shared Rainmeter resources and repeatable deployment tooling
- Guarded Windows Explorer, Windows Terminal, and PowerShell theme integration
- Documented installation, customization, validation, and recovery boundaries
- 328 passing Pester tests with no failures on the merged release state

## Release Boundaries

- Rainmeter and shell customization remain optional.
- AutoHotkey automation and a complete managed Windhawk lifecycle remain deferred.
- Visual helpers target the validated Windows 11 workstation and do not claim
  compatibility with every Windows build or third-party theme combination.

## Release Result

The visual environment was reviewed and squash-merged into `main` through pull
request #5. The merged state passed the complete repository test suite and visual
desktop review before release tagging.

---
# v0.6.0 — Developer Environment Provisioning

**Status**

Released and tagged on `main`

**Release Date**

August 8, 2026

---

## Overview

Version 0.6.0 adds a native Windows developer-environment contract for Project
Hermes. It inventories and safely provisions required tooling, validates Visual
Studio Code extensions and OpenSSH state, reports optional runtime capabilities,
and verifies bounded Remote SSH access without requiring local Linux or container
workloads.

## Highlights

- `Hermes.Developer` v0.6.0 with six documented public commands
- Native Windows tool inventory and previewable approved-package provisioning
- Visual Studio Code extension validation and provisioning
- SSH-agent, loaded-key, host-alias, and bounded Remote SSH validation
- Optional WSL, Docker, Python, Node.js, and .NET capability reporting
- Unified workstation and managed PowerShell profile integration
- Explicit Windows-client and Ubuntu COC-server ownership boundaries
- 328 passing Pester tests with no failures

## Network Boundary

Remote SSH was validated on the trusted home network using hardened key-based
authentication. VPN configuration and untrusted-network validation remain deferred;
this release does not claim secure off-network access.

## Release Result

The implementation was reviewed and squash-merged into `main`. The merged release
state passed the complete profile-isolated test suite and was tagged as `v0.6.0`.

---

# v0.5.0 — Workstation Framework

**Status**

Released and tagged on `main`

**Release Date**

July 20, 2026

---

## Overview

Version 0.5.0 establishes the modular workstation configuration framework used by
Project Hermes. It provides explicit desired state, current-state discovery,
preview behavior, backups where practical, post-change verification, restoration
for reversible settings, and complete validation evidence.

## Highlights

- Shared Core and Common infrastructure
- Explorer, Taskbar, Windows appearance, and Desktop lifecycles
- Managed PowerShell module-loading profile
- Project Hermes Windows Terminal scheme
- Git and Visual Studio Code configuration
- PowerToys configuration
- Explicit Core and Customization WinGet package profiles
- Schema-versioned unified workstation profile spanning ten components
- Portable component configuration data
- 314 passing Pester tests across module and integration suites

## Safety Boundaries

- The unified profile is declarative and does not apply every component automatically.
- WinGet installs only missing approved packages and does not perform blanket upgrades or uninstalls.
- Generated backups, inventories, logs, and workstation state remain excluded from Git.
- Windhawk and Rainmeter visual configuration remain deferred to the visual-integration milestone.

## Release Result

The feature branch was reviewed and merged into `main`, the merged state was
validated, and the release was tagged as `v0.5.0`.

---

# v0.4.0 — Validation Framework

**Status**

Released

**Release Date**

*To be added when officially released.*

---

## Overview

Version 0.4.0 establishes the validation foundation of Project Hermes.

This release introduces a centralized validation framework capable of confirming that a workstation meets the minimum requirements before any deployment tasks are executed.

By validating the environment first, Hermes can detect configuration problems early, resulting in more reliable and repeatable workstation deployments.

---

## Highlights

### Environment Validation

Hermes now validates:

- PowerShell
- Git
- GitHub CLI
- Visual Studio Code
- WinGet
- Repository structure
- Git repository configuration
- Git remote configuration

---

### Repository Improvements

- Added `.gitattributes`
- Standardized repository formatting
- Improved repository consistency

---

### Bug Fixes

- Removed duplicate `gitignore(1)` file

---

## Why This Release Matters

This milestone establishes the deployment validation layer that future versions of Hermes will rely on.

Every future deployment module will benefit from the validation framework introduced in this release.

---

## Looking Ahead

The next milestone (v0.5.0) focuses on transforming Hermes from a deployment framework into a workstation configuration platform.

Planned improvements include:

- Windows configuration
- Explorer configuration
- Windows Terminal configuration
- PowerShell profile deployment
- Git configuration
- Visual Studio Code configuration
- Desktop customization
- Workstation profiles

---

# v0.3.0 — Bootstrap Framework

**Status**

Released

---

## Overview

Version 0.3.0 established the initial architecture of Project Hermes.

This release introduced the bootstrap framework responsible for organizing the repository, installing core development tools, and providing the foundation for future deployment modules.

---

## Highlights

- Bootstrap deployment
- Modular PowerShell architecture
- Core tool installation
- WinGet integration

---

## Why This Release Matters

This version created the foundation that all future Hermes functionality builds upon.

---

# Stable Release Scope

## v1.0.0 — Stable Reproducible Workstation

Project Hermes v1.0.0 is the first stable release of the supported Windows 11 workstation automation framework.

### Release validation

- Full Pester suite: **381 passed, 0 failed**.
- PowerShell parsing: no errors across modules, scripts, and tests.
- Module manifests: **15 valid, 0 invalid**.
- Canonical workstation audit: **11 of 11 components compliant**.
- Orchestration preflight: ready on the supported workstation.
- Recovery readiness: portable backup round-trip and restore-command coverage validated.
- Source quality: clean whitespace check and no unresolved release changes before finalization.
- WireGuard: installation and the Home and Untrusted tunnel profiles are configured and complete. The unstable phone-hotspot attempt is not treated as release-validation evidence.

### Stable scope

The release provides documented assessment, planning, backup, provisioning, configuration, validation, reporting, maintenance, and recovery workflows for the supported Windows 11 and PowerShell 7 workstation profile.

Infrastructure services, AI integrations, enterprise directory management, and future homelab services remain external to the stable workstation framework.

---
