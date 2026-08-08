# Hermes.Maintenance

`Hermes.Maintenance` provides the Project Hermes v0.8 workstation-wide audit and reporting layer.

It coordinates existing component compliance commands rather than replacing them. The module also validates Hermes JSON backups and exports consolidated JSON and Markdown reports.

The Cyber Operations Center repository remains authoritative for infrastructure and incident procedures, including RB-011 through RB-014. Project Hermes produces workstation evidence that can support those procedures without duplicating them.

## Initial workflow

```powershell
Import-Module .\modules\operations\maintenance\Hermes.Maintenance.psd1 -Force

$configuration = Import-PowerShellDataFile `
    .\configs\maintenance\hermes-maintenance-base.psd1

$report = New-HermesMaintenanceReport -Configuration $configuration

Export-HermesMaintenanceReport `
    -Configuration $configuration `
    -Report $report
```

Use `-WhatIf` with `Export-HermesMaintenanceReport` to preview report creation.
