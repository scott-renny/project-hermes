# Project Hermes

> A modular PowerShell framework for provisioning, configuring, and maintaining Windows engineering workstations.

---

## Overview

Project Hermes automates the setup of a complete engineering workstation from a clean Windows installation.

Rather than simply installing software, Hermes provides a repeatable deployment framework capable of configuring Windows, installing development tools, validating system requirements, and preparing a workstation for software engineering, cybersecurity, homelab administration, and infrastructure projects.

The long-term objective is to make rebuilding an entire workstation as simple as running a single PowerShell command.

---

# Current Status

**Current Release**

```
v0.4.0
```

Current development focuses on building the deployment framework before expanding into full workstation customization.

---

# Features

## Bootstrap

- Repository initialization
- Project structure validation
- Initial deployment workflow

## Package Management

- WinGet integration
- Automated software installation
- Modular package collections

## Environment Validation

The environment validator verifies:

- PowerShell
- Git
- GitHub CLI
- Visual Studio Code
- WinGet
- Repository structure
- Git repository status
- Git remote configuration

Run the validator:

```powershell
.\scripts\diagnostics\Test-HermesEnvironment.ps1 -Detailed
```

Typical successful output:

```
Passed:   12
Warnings: 0
Failed:   0
```

---

# Repository Structure

```
Project-Hermes/
│
├── configs/
├── docs/
├── scripts/
│   ├── bootstrap/
│   ├── diagnostics/
│   └── modules/
│
├── README.md
├── CHANGELOG.md
├── BUILD_JOURNAL.md
└── PROJECT_CHARTER.md
```

---

# Roadmap

## v0.4.0

✔ Bootstrap Framework

✔ Environment Validation

✔ Repository Standards

---

## v0.5.0

Planned:

- Windows configuration
- Explorer configuration
- Windows Terminal configuration
- PowerShell profile deployment
- VS Code configuration
- Git configuration
- Desktop customization

---

## Future Releases

- Docker provisioning
- WSL configuration
- SSH deployment
- PowerToys automation
- Wallpaper deployment
- Workstation profiles
- One-command workstation provisioning

---

# Development Philosophy

Project Hermes follows several engineering principles:

- Modular architecture
- Idempotent scripts
- Repeatable deployments
- Clear documentation
- Git-first workflow
- Incremental releases

Every feature should be independently testable and safe to execute multiple times.

---

# Contributing

Contributions, suggestions, and issues are welcome.

Please read:

- CONTRIBUTING.md
- ENGINEERING_STANDARD.md
- SECURITY.md

before submitting changes.

---

# License

This project is released under the MIT License.
