# Project Hermes Releases

This document provides a high-level overview of each Project Hermes release.

While the `CHANGELOG.md` contains a technical record of every change, this document focuses on the goals, major features, and overall progress of each release.

---

# Version History

| Version | Status | Summary |
|----------|--------|---------|
| v0.4.0 | ✅ Released | Validation Framework |
| v0.3.0 | ✅ Released | Bootstrap Framework |

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
| v0.5.0 | Windows configuration and desktop customization |
| v0.6.0 | Windows Terminal and PowerShell automation |
| v0.7.0 | Visual Studio Code deployment |
| v0.8.0 | Docker, WSL, and developer tooling |
| v0.9.0 | Multi-profile workstation deployments |
| v1.0.0 | Stable production release |
