# Hermes.Winget

Hermes.Winget audits and installs explicitly approved workstation packages.

## Principles

- Package profiles are additive and portable.
- Only missing approved packages are installed.
- Existing packages are never uninstalled.
- Blanket upgrades are never performed.
- Personal applications remain visible in inventories but are not modified.

## Initial profiles

- Core: shell, source control, editor, terminal, archive tooling
- Customization: PowerToys, Rainmeter, Windhawk

Security, productivity, media, and personal profiles can be added later without
changing the module.
