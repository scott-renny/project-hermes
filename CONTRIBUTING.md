# Contributing to Project Hermes

**Document Control**

| Field | Value |
|---|---|
| Document | Contributing Guide |
| Project | Project Hermes |
| Version | 1.0.0 |
| Status | Active |
| Last Updated | July 19, 2026 |

---

# 1. Purpose

This guide defines how changes are proposed, implemented, reviewed, validated, documented, and committed in Project Hermes.

Although Project Hermes is currently maintained by a single owner, all work should follow the same standards expected in a collaborative engineering repository.

---

# 2. Contribution Principles

All contributions should be:

- Purposeful
- Documented
- Reproducible
- Maintainable
- Validated
- Consistent with the Project Charter
- Compliant with the Engineering Documentation Standard

---

# 3. Before Making Changes

Before implementation:

1. Review the current roadmap.
2. Confirm the change is within project scope.
3. Identify all affected files.
4. Review related Build Journal entries.
5. Confirm dependencies and risks.
6. Define validation criteria.

Changes that expand project scope should first be recorded as a proposed charter or roadmap update.

---

# 4. Branching Strategy

Use short-lived branches for meaningful changes.

Recommended branch names:

```text
docs/update-roadmap
feat/powershell-profile
feat/powertoys-layout
fix/startup-script
refactor/config-structure
```

Branch naming format:

```text
<type>/<short-description>
```

Recommended types:

- `docs`
- `feat`
- `fix`
- `refactor`
- `test`
- `build`
- `chore`

Direct commits to the default branch should be limited to minor administrative corrections.

---

# 5. Commit Standard

Project Hermes uses Conventional Commits.

Examples:

```text
docs: add workstation setup guide
feat: add PowerShell profile bootstrap script
fix: correct workspace restoration path
refactor: reorganize configuration directories
test: add validation checklist for startup automation
chore: update repository metadata
```

Commit messages should:

- Use the imperative mood.
- Be specific.
- Describe one logical change.
- Avoid vague wording such as `update files` or `misc changes`.

For substantial commits, include a description explaining:

- What changed
- Why it changed
- How it was validated
- Any follow-up work

---

# 6. Documentation Requirements

Every implementation change must update the applicable documentation.

Possible affected files include:

- `README.md`
- `ROADMAP.md`
- `BUILD_JOURNAL.md`
- `CHANGELOG.md`
- Installation guides
- Configuration references
- Troubleshooting guides
- Validation documents

Documentation should answer:

- Why was the change made?
- What changed?
- How is it implemented?
- How was it validated?
- What was learned?

---

# 7. File Standards

## Markdown

- Use clear heading hierarchy.
- Use descriptive section names.
- Keep tables readable.
- Use fenced code blocks with language identifiers where practical.
- Use relative links for repository files.
- Avoid unnecessary decorative formatting.

## PowerShell

- Use approved verbs.
- Use meaningful function and variable names.
- Include comments where intent is not obvious.
- Add error handling for destructive or failure-prone operations.
- Avoid hard-coded user-specific paths where possible.
- Support repeatable execution.

## AutoHotkey

- Organize hotkeys by function.
- Document non-obvious key combinations.
- Avoid conflicts with Windows and application shortcuts.
- Include a safe method to disable or exit scripts.

## Configuration Files

- Keep user-specific secrets out of the repository.
- Prefer templates and examples.
- Document required manual values.
- Preserve compatibility with repository structure.

---

# 8. Security Requirements

Do not commit:

- Passwords
- API keys
- Tokens
- Private certificates
- Recovery codes
- Personal identifiers
- Private network details that are not required
- Machine-specific secrets

Sensitive values should be stored outside the repository and referenced through documented placeholders, environment variables, or local configuration files excluded by `.gitignore`.

---

# 9. Validation Requirements

Before a change is considered complete:

- Confirm the feature works as intended.
- Confirm existing functionality still works.
- Verify paths and commands.
- Verify Markdown rendering.
- Check links.
- Confirm no secrets are present.
- Update the Build Journal.
- Update the Changelog when release-relevant.
- Synchronize the README when repository structure, status, or capabilities change.

Validation results should be recorded in the Build Journal.

---

# 10. Pull Request Standard

A pull request should include:

## Summary

A concise explanation of the change.

## Reason

Why the change is needed.

## Files Changed

A list of added, modified, or removed files.

## Validation

The tests or checks performed.

## Documentation

The documentation updated as part of the change.

## Risks

Known limitations, compatibility concerns, or follow-up work.

---

# 11. Review Checklist

Before approval:

- Scope is appropriate.
- Engineering standards are followed.
- Naming is consistent.
- Documentation is complete.
- Validation is recorded.
- Security risks have been considered.
- No unrelated changes are included.
- README is synchronized where required.
- Build Journal is updated.
- Changelog is updated where required.

---

# 12. Definition of Done

A contribution is complete only when:

- Implementation is finished.
- Validation has passed.
- Documentation is synchronized.
- Build Journal is updated.
- Changelog is updated when applicable.
- Commit history is clear.
- The repository remains reproducible.

---

# 13. Issue Reporting

Issues should include:

- Clear title
- Problem description
- Expected behavior
- Actual behavior
- Reproduction steps
- Screenshots or logs where useful
- Environment details
- Known workarounds

Security-related issues should follow `SECURITY.md` rather than being posted publicly.

---

# 14. Related Documents

- `README.md`
- `PROJECT_CHARTER.md`
- `ENGINEERING_STANDARD.md`
- `ROADMAP.md`
- `BUILD_JOURNAL.md`
- `CHANGELOG.md`
- `SECURITY.md`

---

# 15. Revision History

| Version | Date | Description |
|---|---|---|
| 1.0.0 | July 19, 2026 | Initial contributing guide created. |
