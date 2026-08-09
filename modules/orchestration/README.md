# Hermes.Orchestration

`Hermes.Orchestration` is the v0.9 unified entry point for Project Hermes.

It turns the portable workstation profile into an ordered plan, validates every
component before execution, supports audit and apply modes, records resumable state,
and exports a consolidated JSON and Markdown report.

Apply mode remains explicit and supports `WhatIf`. Required component failures can
stop the run; optional-component behavior is controlled by configuration.

Run results distinguish successful execution from full desired-state compliance and
include component, compliant, drifted, planned, and failure counts. Preview runs do
not persist orchestration state files.

Apply persistent path-bearing settings such as Desktop and PowerShell only from the
canonical Project Hermes checkout. Temporary worktrees are intended for development,
auditing, and preview operations.
