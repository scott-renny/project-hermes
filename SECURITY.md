# Security Policy

**Document Control**

| Field | Value |
|---|---|
| Document | Security Policy |
| Project | Project Hermes |
| Version | 1.1.0 |
| Status | Active |
| Last Updated | August 9, 2026 |

---

# 1. Purpose

This document defines the security expectations for Project Hermes and establishes how sensitive information, vulnerabilities, and security-related changes are handled.

---

# 2. Scope

This policy applies to:

- Repository contents
- Scripts
- Configuration files
- Documentation
- Build artifacts
- Future automation

---

# 3. Security Principles

Project Hermes follows these principles:

- Least privilege
- Secure by default
- Defense in depth
- Reproducibility
- Documented changes
- No secrets committed to source control

---

# 4. Supported Versions

| Version | Supported |
|---|:---:|
| 0.x.x | ❌ |
| 1.x.x | ✅ |

---

# 5. Responsible Disclosure

If a security issue is discovered:

1. Use GitHub's private vulnerability-reporting feature from the repository Security tab when available.
2. Do not include credentials, exploit details, or private infrastructure data in a public issue.
3. If private reporting is unavailable, open a minimal public issue requesting a private contact channel without disclosing sensitive details.
4. Assess impact and affected files privately.
5. Implement and validate a fix.
6. Record the resolution in the Build Journal and document release-impacting fixes in the Changelog.

---

# 6. Secret Management

Never commit:

- Passwords
- API keys
- Tokens
- SSH private keys
- Recovery codes
- Private certificates
- Environment files containing secrets

Use placeholders, environment variables, or local files excluded by `.gitignore`.

---

# 7. Secure Development Requirements

Before committing:

- Review scripts for unsafe commands.
- Validate file permissions where applicable.
- Remove debugging artifacts.
- Check for hard-coded paths or credentials.
- Verify no sensitive data is included.

---

# 8. Dependency Management

When adding software:

- Prefer actively maintained projects.
- Verify download sources.
- Record version numbers.
- Document installation and configuration.

---

# 9. Incident Response

For confirmed security issues:

- Contain the issue.
- Assess impact.
- Restore secure operation.
- Document root cause.
- Implement preventive actions.
- Update documentation.

---

# 10. Security Review Checklist

- No secrets committed
- Documentation updated
- Validation completed
- Build Journal updated
- Changelog updated (if applicable)
- README synchronized (if applicable)

---

# 11. Related Documents

- README.md
- PROJECT_CHARTER.md
- ENGINEERING_STANDARD.md
- CONTRIBUTING.md
- BUILD_JOURNAL.md
- CHANGELOG.md

---

# 12. Revision History

| Version | Date | Description |
|---|---|---|
| 1.0.0 | July 19, 2026 | Initial security policy. |
| 1.1.0 | August 9, 2026 | Updated supported versions and private vulnerability-reporting guidance for v1.0.0. |
