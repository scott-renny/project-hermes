# Workstation Profile Format

Project Hermes uses a versioned PowerShell data file to describe one unified
workstation baseline without duplicating component settings.

The initial profile is stored at:

```text
configs/profiles/hermes-workstation-base.psd1
```

## Responsibilities

The unified profile defines:

- Schema version and human-readable identity
- Supported Windows and PowerShell platform
- Component execution order
- Enabled and required component state
- Repository-relative module manifest paths
- Repository-relative component configuration paths

The profile does not apply settings itself. Component modules remain responsible
for validating, backing up, applying, verifying, and restoring their own state.
A future orchestrator can consume this profile without taking policy ownership
away from those modules.

## Component Contract

Each component entry contains:

| Field | Purpose |
|---|---|
| `Enabled` | Includes or excludes the component from the selected profile. |
| `Required` | Identifies whether absence or failure must stop deployment. |
| `ModulePath` | Repository-relative path to the component module manifest. |
| `ConfigurationPath` | Repository-relative path to the component desired state. |

Paths must remain relative so the repository can be cloned to another supported
location without editing the profile.

## Required and Optional Components

Core Windows configuration, package auditing, Git, and PowerShell initialization
are required by the base workstation profile. Terminal, Visual Studio Code, and
PowerToys are enabled but non-required application components so future orchestration
can report their absence without treating the underlying Windows baseline as failed.

## Validation

The integration suite verifies that:

- The profile imports successfully.
- The schema and platform metadata are supported.
- Every component appears exactly once in execution order.
- Every referenced module manifest and configuration file exists.
- Every module manifest is valid.
- Every component configuration passes its owning module's validator.

Run the integration test with:

```powershell
Invoke-Pester `
    -Path .\tests\workstation\Hermes.WorkstationProfile.Tests.ps1 `
    -Output Detailed
```
