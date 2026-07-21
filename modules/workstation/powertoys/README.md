# Hermes.PowerToys

Hermes.PowerToys manages a restrained, reproducible PowerToys baseline for Project Hermes.

## Scope

- Global startup, theme, elevation, experimentation, and update-tour choices
- Selected PowerToys feature enablement
- Preservation of unmanaged settings and features
- Exact-byte backup and restoration
- Validation, compliance testing, WhatIf, and idempotent application

## Design boundary

This module manages only the global settings.json file. Detailed per-utility
preferences, hotkeys, FancyZones layouts, and installation are intentionally
excluded from v0.5.0.

The baseline uses Command Palette instead of enabling the older PowerToys Run
at the same time. Utilities that can keep the laptop awake or add persistent
on-screen effects are disabled by default.
