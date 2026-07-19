# Project Hermes

<h1 align="center">Project Hermes</h1>

<p align="center">
<b>Engineering Workstation Automation Framework</b>
</p>

<p align="center">

![Status](https://img.shields.io/badge/Status-Active%20Development-orange?style=for-the-badge)
![PowerShell](https://img.shields.io/badge/PowerShell-7+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-11-0078D6?style=for-the-badge&logo=windows11&logoColor=white)
![License](https://img.shields.io/github/license/scott-renny/project-hermes?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/scott-renny/project-hermes?style=for-the-badge)
![Repo Size](https://img.shields.io/github/repo-size/scott-renny/project-hermes?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/scott-renny/project-hermes?style=for-the-badge)

</p>

---

## Overview

Project Hermes is a modular PowerShell framework designed to automate the provisioning, configuration, validation, and long-term maintenance of Windows engineering workstations.

Instead of manually configuring every new Windows installation, Hermes provides a repeatable deployment process that installs development tools, validates system requirements, configures the operating system, and prepares a workstation for software engineering, cybersecurity, homelab administration, and infrastructure projects.

The long-term objective is to transform a clean Windows installation into a fully configured engineering workstation through a consistent, repeatable deployment process.

---

# Quick Start

Clone the repository:

```powershell
git clone https://github.com/scott-renny/project-hermes.git
```

Move into the project:

```powershell
cd project-hermes
```

Run the environment validator:

```powershell
.\scripts\diagnostics\Test-HermesEnvironment.ps1 -Detailed
```

---

# Current Release

## v0.4.0 — Validation Framework

### Included

- Bootstrap deployment framework
- Modular PowerShell architecture
- WinGet package management
- Environment validation
- Git validation
- GitHub CLI validation
- Visual Studio Code validation
- Repository validation
- Git remote validation
- Repository standards
- `.gitattributes`

---

# Repository Structure

```text
Project-Hermes
│
├── configs/
├── docs/
├── scripts/
│   ├── bootstrap/
│   ├── diagnostics/
│   └── modules/
│
├── README.md
├── BUILD_JOURNAL.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── ENGINEERING_STANDARD.md
├── PROJECT_CHARTER.md
└── SECURITY.md
```

---

# Features

## Bootstrap

- Repository initialization
- Initial deployment workflow
- Modular script loading

## Package Management

- WinGet integration
- Modular package collections
- Automated software installation

## Environment Validation

Hermes validates the local workstation before deployment by checking:

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

Expected output:

```text
Passed:   12
Warnings: 0
Failed:   0
```

---

# Roadmap

## ✅ v0.4.0

- Bootstrap framework
- Validation framework
- Repository standards

## 🚧 v0.5.0

Planned work:

- Windows configuration
- Explorer configuration
- Windows Terminal configuration
- PowerShell profile deployment
- Git configuration
- Visual Studio Code configuration
- Desktop customization
- Workstation profiles

## Future Releases

- Docker provisioning
- WSL automation
- SSH deployment
- PowerToys configuration
- Wallpaper deployment
- Multi-profile workstation support
- One-command workstation provisioning

---

# Engineering Principles

Project Hermes is built around several engineering principles.

- Modular architecture
- Idempotent scripting
- Repeatable deployments
- Documentation-first development
- Git-first workflow
- Automated validation
- Incremental releases

Every script should be safe to execute multiple times and produce predictable, repeatable results.

---

# Documentation

Additional project documentation:

- BUILD_JOURNAL.md
- CHANGELOG.md
- PROJECT_CHARTER.md
- CONTRIBUTING.md
- ENGINEERING_STANDARD.md
- SECURITY.md

---

# Long-Term Vision

Project Hermes is being developed as a reusable workstation deployment framework capable of automating software installation, operating system configuration, validation, and engineering environment provisioning from a clean Windows installation.

The framework is designed to support future expansion through additional deployment modules while maintaining a consistent and repeatable deployment workflow.

---

# License

Released under the MIT License.
