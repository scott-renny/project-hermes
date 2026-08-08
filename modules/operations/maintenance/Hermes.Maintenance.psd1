@{
    RootModule        = 'Hermes.Maintenance.psm1'
    ModuleVersion     = '0.8.0'
    GUID              = 'a905253a-eef0-46c7-82ed-66eb30e9971d'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Audits Project Hermes workstation drift, backup health, and maintenance reporting.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Test-HermesMaintenanceConfiguration'
        'Get-HermesBackupHealth'
        'Invoke-HermesWorkstationAudit'
        'New-HermesMaintenanceReport'
        'Export-HermesMaintenanceReport'
    )

    CmdletsToExport    = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{ PSData = @{
        Tags = @('ProjectHermes', 'Maintenance', 'DriftDetection', 'Backup', 'Reporting')
        ProjectUri = 'https://github.com/scott-renny/project-hermes'
        LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes = 'Initial v0.8.0 workstation audit, backup-health, and reporting contract.'
    }}
}
