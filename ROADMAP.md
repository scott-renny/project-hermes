# Project Hermes Roadmap

## Document Control

| Field | Value |
|---|---|
| Document | Project Roadmap |
| Project | Project Hermes |
| Document Version | 2.0.0 |
| Status | Active |
| Primary Platform | Windows 11 Home |
| Current Milestone | v0.5.0 — Workstation Framework |
| Last Updated | July 20, 2026 |

---

## 1. Purpose

This roadmap defines the planned evolution of Project Hermes from a workstation bootstrap and validation project into a stable Windows engineering workstation automation framework.

It identifies release objectives, deliverables, dependencies, quality gates, deferred scope, and completion criteria. Detailed implementation history belongs in `BUILD_JOURNAL.md`; release-focused changes belong in `CHANGELOG.md`.

---

## 2. Project Vision

Create a documented, modular, testable, and reproducible PowerShell framework capable of transforming a supported Windows 11 installation into a configured engineering workstation while preserving validation evidence, backups, restore paths, and clear operational control.

Hermes should eventually support a complete workstation lifecycle:

```text
Assess
  ↓
Plan
  ↓
Back up
  ↓
Provision
  ↓
Configure
  ↓
Validate
  ↓
Report
  ↓
Maintain or restore
```

---

## 3. Guiding Principles

- Documentation accompanies implementation.
- State-changing operations are deliberate and reversible where practical.
- Modules validate input before modifying the workstation.
- Current state is backed up before configuration changes.
- Applied state is verified rather than assumed.
- Repeated execution should be safe and predictable.
- Shared technical mechanics are separated from component-specific policy.
- Generated workstation data remains local unless explicitly sanitized for publication.
- Windows 11 Home compatibility is considered before adopting Pro-only behavior.
- No milestone is complete until required validation passes.

---

## 4. Release Overview

| Release | Focus | Status |
|---|---|---|
| v0.1.0 | Repository and bootstrap foundation | Complete |
| v0.2.0 | Shared core infrastructure | Complete |
| v0.3.1 | Safe Explorer configuration workflow | Complete |
| v0.4.0 | Environment validation framework | Complete |
| v0.5.0 | Workstation configuration framework | In progress |
| v0.6.0 | Developer environment provisioning | Planned |
| v0.7.0 | Visual environment and productivity integration | Planned |
| v0.8.0 | Recovery, maintenance, and reporting | Planned |
| v0.9.0 | Integrated orchestration and release candidate | Planned |
| v1.0.0 | Stable reproducible workstation release | Planned |

Release scope may be refined as implementation evidence becomes available. Any material change must be reflected in this roadmap, the build journal, and the changelog.

---

## 5. Completed Releases

### v0.1.0 — Repository and Bootstrap Foundation

#### Objectives

- Establish Project Hermes documentation and governance.
- Create the initial repository structure.
- Capture a Windows workstation baseline.
- Begin a repeatable bootstrap workflow.

#### Outcomes

- Repository foundation established.
- Bootstrap and baseline collection introduced.
- Core documentation created.
- Initial project standards defined.

---

### v0.2.0 — Shared Core Infrastructure

#### Objectives

- Move from a single initialization script toward reusable PowerShell infrastructure.
- Improve portability, logging, state, and execution reporting.

#### Outcomes

- Modular initialization workflow.
- Portable repository-root discovery.
- Structured logs, state, and summaries.
- Administrator-aware inventory behavior.
- Winget timeout and skip controls.
- Corrected installed-program inventory.

---

### v0.3.1 — Safe Explorer Configuration Workflow

#### Objectives

- Establish a safe Windows configuration pattern.
- Validate desired state and preserve rollback information.

#### Outcomes

- Explorer settings discovery and configuration.
- Backup support.
- Configuration testing and verification.
- Initial workstation module test pattern.

---

### v0.4.0 — Environment Validation Framework

#### Objectives

- Detect missing prerequisites before deployment.
- Validate the repository and workstation environment consistently.

#### Outcomes

- PowerShell, Git, GitHub CLI, Visual Studio Code, and WinGet validation.
- Repository structure validation.
- Git repository and remote validation.
- Repository formatting standards.
- Reusable environment validation architecture.

---

## 6. Active Release: v0.5.0 — Workstation Framework

### Objective

Establish a consistent, testable lifecycle for Windows workstation configuration modules.

### Standard Module Lifecycle

Where applicable, workstation modules should provide:

```text
Get-Hermes<Component>Settings
Test-Hermes<Component>Configuration
Test-Hermes<Component>Settings
Backup-Hermes<Component>Settings
Set-Hermes<Component>Settings
Restore-Hermes<Component>Settings
```

### Required Module Behaviors

- Explicit desired-state validation
- Current-state discovery
- Idempotent compliance testing
- Backup before mutation
- `ShouldProcess`, `-WhatIf`, and `-Confirm` for state changes
- Post-change verification
- Restore support where configuration is reversible
- Complete comment-based help
- Module-specific documentation
- Manifest, import, export, and Pester validation

### Current Components

| Component | Deliverable | Status |
|---|---|---|
| Repository hygiene | Generated-data exclusions and cleanup | Complete |
| `Hermes.Explorer` | Complete Explorer lifecycle | Complete and tested |
| `Hermes.Common` | Shared logging, validation, Registry, JSON, and shell helpers | Complete and tested |
| `Hermes.Taskbar` | Selected Windows 11 taskbar settings | Complete and tested |
| `Hermes.Windows` | Supported Windows personalization settings | Complete and tested |
| `Hermes.PowerShell` | Safe managed profile and automatic module initialization | Complete and tested |
| `Hermes.Terminal` | Windows Terminal configuration | Planned |
| `Hermes.Git` | Git workstation configuration | Planned |
| `Hermes.VSCode` | Visual Studio Code configuration | Planned |
| `Hermes.Desktop` | Native wallpaper, fit mode, and desktop-icon visibility | Complete and tested |
| Workstation profiles | Profile-driven desired state | Planned |
| Initial Windows visual profile | Version-controlled dark personalization baseline | Complete and tested |
| Initial Taskbar profile | Windows Home-compatible operations Taskbar baseline | Complete and tested |
| Initial Desktop profile | Portable wallpaper and native desktop baseline | Complete and tested |
| Integrated validation | Full v0.5.0 workstation test pass | Planned |

### Shared Architecture Work

Completed shared architecture work:

- Established one-way Taskbar dependencies on `Hermes.Core` and `Hermes.Common` without circular imports.
- Standardized Taskbar use of Core backup services and Common Registry and Explorer helpers.
- Migrated `Hermes.Explorer` to the same one-way Core and Common dependency pattern without changing its public API.
- Preserved component-specific configuration policy inside `Hermes.Taskbar`.
- Preserved component-specific configuration policy inside `Hermes.Explorer`.
- Validated both shared-helper integrations through their complete module test suites.
- Finalized Core as the owner of repository-aware identity and backup infrastructure.
- Finalized Common as the owner of repository-independent technical helpers.
- Established Core and Common as independent peer modules with no mutual imports.
- Aligned Explorer's PowerShell requirement with its mandatory Core dependency.

Remaining shared architecture work:

- Standardize dependency discovery across remaining workstation modules.
- Reuse test helpers only where reuse improves clarity without hiding module behavior.

### v0.5.0 Acceptance Criteria

- Every included module has a valid manifest.
- Every included module imports without errors.
- Public exports match module manifests.
- All exported functions have complete help.
- All included Pester suites pass.
- State-changing operations support preview behavior where appropriate.
- Backup and restore behavior is validated for reversible settings.
- Windows 11 Home compatibility is documented.
- Generated workstation data remains excluded from version control.
- Root and module documentation reflect the final implementation.
- The release is merged into `main` only after integrated validation.

### v0.5.0 Exit Deliverables

- Workstation configuration module set
- Shared helper integration
- Workstation profile format
- Validation evidence
- Updated installation and usage documentation
- Updated build journal and changelog
- Tagged v0.5.0 release

---

## 7. v0.6.0 — Developer Environment Provisioning

### Objective

Provision and validate the development tools required for engineering, cybersecurity, automation, and infrastructure work.

### Planned Scope

- WinGet package collections
- Git and GitHub CLI installation validation
- Visual Studio Code installation and extension management
- PowerShell 7 installation and module management
- Windows Terminal provisioning
- OpenSSH client configuration where supported
- WSL capability assessment and supported setup
- Docker capability assessment and supported setup
- Python and Node.js evaluation where required by later tooling

### Constraints

- Windows 11 Home must remain supported.
- Hyper-V-only assumptions must be avoided or documented as unavailable.
- Optional tools must be profile-controlled rather than installed unconditionally.
- Package identifiers and installation sources must be explicit and reviewable.

### Acceptance Criteria

- A selected developer profile can be applied repeatedly without unnecessary reinstalls.
- Package installation results are logged and summarized.
- Failed or unavailable dependencies are reported clearly.
- Tool versions and availability can be validated after provisioning.
- Installation behavior supports preview or explicit confirmation where practical.

---

## 8. v0.7.0 — Visual Environment and Productivity Integration

### Objective

Apply the Project Hermes visual identity and productivity configuration without compromising stability or daily usability.

### Planned Scope

- Project Hermes design language
- Wallpaper and approved visual assets
- PowerToys configuration
- Windhawk configuration management
- Rainmeter configuration and selected widgets
- AutoHotkey workflow automation
- Font and icon deployment where licensing permits
- Desktop zones and launch strategy
- Consistent backup and restore for managed settings

### Acceptance Criteria

- Visual changes remain subordinate to functionality.
- Third-party tools are optional and profile-controlled.
- All distributed assets have verified licensing or original ownership.
- Each managed configuration has an installation, validation, and recovery path.
- The resulting environment remains suitable for daily work.

---

## 9. v0.8.0 — Recovery, Maintenance, and Reporting

### Objective

Support long-term workstation operation, repair, drift detection, and evidence-based maintenance.

### Planned Scope

- Unified backup inventory
- Configuration restore orchestration
- Repair workflows
- Drift detection
- Workstation health checks
- Maintenance scripts
- Structured execution summaries
- Human-readable reports
- Sanitized sample report formats
- Backup retention policy

### Acceptance Criteria

- Hermes can identify managed settings that differ from the selected profile.
- Recovery operations are explicit and validated.
- Reports separate success, warning, skipped, and failed outcomes.
- Sensitive workstation data is excluded from public output by default.
- Maintenance tasks do not run automatically without documented user control.

---

## 10. v0.9.0 — Integrated Orchestration and Release Candidate

### Objective

Combine stable modules into a coherent end-to-end workstation deployment workflow and prepare the framework for a stable release.

### Planned Scope

- Unified entry point
- Profile selection
- Preflight validation
- Dependency ordering
- Elevation-aware execution
- Resume behavior
- Module-level inclusion and exclusion
- Centralized results and final report
- Failure recovery guidance
- Full clean-install rehearsal

### Acceptance Criteria

- A supported workstation profile can be deployed from a documented starting state.
- The orchestrator does not require every optional component.
- Failed steps do not hide successful or skipped results.
- Resume behavior avoids repeating completed destructive or expensive work.
- All included module suites and integration tests pass.
- Release documentation is complete enough for an external tester.

---

## 11. v1.0.0 — Stable Reproducible Workstation

### Objective

Release the first stable Project Hermes workstation framework.

### Required Outcomes

- Stable documented public workflow
- Supported Windows edition and PowerShell requirements
- Complete configuration profile documentation
- Reproducible supported deployment
- Validated backup and restore procedures
- Clean test and analysis results
- Security and privacy review
- Documentation audit
- Tagged release and release notes

### Definition of Stable

Stable does not mean every possible workstation feature is implemented. It means the documented v1.0.0 scope behaves predictably, is validated, can be maintained, and does not rely on undocumented manual intervention.

---

## 12. Deferred and External Integrations

The following areas are not dependencies for the initial Hermes workstation framework:

- Server infrastructure supplied by Project Atlas
- Broader Cyber Operations Center architecture and security standards
- Artificial intelligence integration
- Enterprise Active Directory or centralized device management
- Infrastructure-specific monitoring dashboards
- Homelab services that do not yet exist

Hermes may integrate with these projects later through separate, documented milestones. Placeholder dependencies should not be introduced before the related system exists.

---

## 13. Quality Gates

Every implementation milestone must satisfy the applicable gates.

### Source Quality

- Strict mode enabled where appropriate
- No unreviewed secrets or machine-specific data
- Consistent formatting and naming
- Explicit exports
- Meaningful error messages
- No unsupported silent failure paths

### Module Quality

- Manifest validation passes
- Module import passes
- Exported command inspection passes
- Complete comment-based help
- `ShouldProcess` for applicable mutations
- Idempotency validated where practical

### Test Quality

- Pester suite passes
- Success and failure paths covered
- `-WhatIf` behavior covered where applicable
- Tests isolate filesystem and Registry state
- Tests do not restart the active shell or make uncontrolled persistent changes

### Documentation Quality

- Module README synchronized
- Root README synchronized when architecture or status changes
- Changelog updated
- Build journal updated
- Roadmap updated when scope or sequencing changes

### Release Quality

- Integrated validation passes
- Working tree is clean
- Release branch is current with its remote
- Release notes match implementation
- Tag is created only after merge and final validation

---

## 14. Dependencies

### Required

- Windows 11 Home or a documented compatible edition
- PowerShell 7+ as the primary execution environment
- Git
- GitHub repository access for source management
- Pester for module validation

### Optional by Profile or Milestone

- WinGet
- GitHub CLI
- Visual Studio Code
- Windows Terminal
- WSL
- Docker
- PowerToys
- Rainmeter
- Windhawk
- AutoHotkey

Optional dependencies must be detected and reported rather than assumed.

---

## 15. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Scope expansion | Delayed milestones and incomplete modules | Use release boundaries and explicit deferred scope. |
| Windows update changes | Registry or shell behavior may change | Validate supported builds and verify post-change state. |
| Third-party tool changes | Installation or configuration may fail | Pin documented identifiers, validate versions, and isolate optional components. |
| Documentation drift | Repository guidance becomes misleading | Synchronize documentation as a completion gate. |
| Machine-specific data exposure | Privacy or security incident | Ignore runtime output and review examples before publication. |
| Shared module coupling | Circular dependencies and fragile imports | Define dependency direction before migration. |
| Over-abstraction | Common helpers become harder to use than direct code | Extract only proven shared mechanics. |
| Insufficient rollback | Configuration changes become difficult to recover | Back up before mutation and test restore paths. |

---

## 16. Success Metrics

- All released module test suites pass.
- All released modules have synchronized documentation.
- Supported configuration workflows are idempotent where practical.
- Reversible settings have validated backup and restore paths.
- Generated workstation data is excluded from public source control.
- A supported workstation can be reproduced from repository documentation.
- A clean v1.0.0 deployment requires no undocumented manual correction.

---

## 17. Revision History

| Version | Date | Description |
|---|---|---|
| 1.0.0 | July 19, 2026 | Initial phase-oriented project roadmap. |
| 2.0.0 | July 20, 2026 | Replaced the phase-only plan with a release-oriented roadmap aligned to the modular workstation architecture. |
