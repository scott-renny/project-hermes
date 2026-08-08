# Project Hermes Releases

This document provides a high-level overview of each Project Hermes release.

While the `CHANGELOG.md` contains a technical record of every change, this document focuses on the goals, major features, and overall progress of each release.

---

# Version History

| Version | Status | Summary |
|----------|--------|---------|
| v0.7.0 | ✅ Released | Visual Environment and Productivity Integration |
| v0.6.0 | ✅ Released | Developer Environment Provisioning |
| v0.5.0 | ✅ Released | Workstation Framework |
| v0.4.0 | ✅ Released | Validation Framework |
| v0.3.0 | ✅ Released | Bootstrap Framework |

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

# Future Releases

The following milestones are currently planned.

| Version | Planned Focus |
|----------|---------------|

| v0.8.0 | Recovery, maintenance, drift detection, and reporting |
| v0.9.0 | Integrated orchestration and release candidate |
| v1.0.0 | Stable production release |
