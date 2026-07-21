# Shared Module Architecture

## Status

**Decision:** Accepted  
**Applies to:** Project Hermes v0.5.0 and later  
**Last Updated:** July 20, 2026

## Purpose

This document defines the stable responsibility and dependency boundary between `Hermes.Core`, `Hermes.Common`, and Project Hermes component modules.

## Dependency direction

```text
Component module
├── imports Hermes.Core when repository or backup infrastructure is required
└── imports Hermes.Common when reusable technical helpers are required

Hermes.Core   ── does not import ──> Hermes.Common
Hermes.Common ── does not import ──> Hermes.Core
```

Shared modules are peers. Neither is a prerequisite of the other.

## Hermes.Core responsibility

Core owns repository-aware framework infrastructure and persistent Hermes contracts:

- Repository-root and project-version discovery
- Hermes identifier generation
- Standardized backup envelope creation
- Backup schema and module identity validation
- Default backup-path resolution
- Standardized backup reading

Core excludes Registry operations, general logging presentation, generic JSON utilities, environment validation, shell control, and component policy.

## Hermes.Common responsibility

Common owns reusable, repository-independent technical helpers:

- Console and optional file logging
- Administrator, operating-system, and PowerShell validation
- Safe Registry path, read, write, and removal operations
- Generic UTF-8 JSON file import and export
- Windows Explorer restart handling

Common excludes repository discovery, project identity, Hermes backup envelopes, backup storage policy, component schemas, desired-state definitions, and orchestration.

## Component module responsibility

Component modules own one configuration area's policy and lifecycle:

- Supported settings and desired-state model
- Component-specific validation and state interpretation
- Registry or file mappings
- Compliance comparison
- Component backup metadata
- Apply and restore sequencing
- Post-change verification
- Component documentation and tests

A component may import either shared module or both. `Hermes.Explorer` and `Hermes.Taskbar` are the reference implementations.

## PowerShell compatibility

- `Hermes.Common` targets PowerShell 5.1 and remains independent of Core.
- `Hermes.Core` requires PowerShell 7.0.
- A component importing Core must require PowerShell 7.0 or later.
- A component importing only Common may declare 5.1 compatibility only when its own implementation and tests support it.
- PowerShell 7+ remains the primary Project Hermes environment.

A manifest must never declare a lower requirement than a mandatory imported dependency.

## JSON ownership

Core internally serializes and validates the Hermes backup envelope. Common provides generic JSON file operations for callers that do not require that envelope. This is a deliberate separation, not a duplicated public contract.

## Change rules

A function belongs in a shared module only when:

1. At least two real consumers need the same technical behavior.
2. It contains no component-specific desired-state policy.
3. It creates no circular import.
4. Its compatibility requirements are explicit.
5. It has complete help and isolated tests.
6. Moving it reduces duplication without hiding essential component behavior.

Potential shared behavior remains private to its first consumer until these conditions are satisfied.

## Validation requirements

Shared-module changes require manifest validation, clean import, exact export validation, the complete shared-module test suite, affected consumer regression tests, documentation synchronization, and confirmation that no circular dependency was introduced.

## Current decision

No production functions need to move between Core and Common. Their public APIs represent distinct concerns. The required correction is to enforce their boundary, align consumer manifests with transitive requirements, and use them consistently from component modules.
