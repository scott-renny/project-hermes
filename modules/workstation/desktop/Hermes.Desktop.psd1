@{
    RootModule        = 'Hermes.Desktop.psm1'
    ModuleVersion     = '0.5.0'
    GUID              = '8a91785b-8a08-49db-bfa9-c7fbd1fc5f1e'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Manages, validates, backs up, applies, verifies, and restores supported native Windows desktop settings for Project Hermes.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-HermesDesktopSettings'
        'Test-HermesDesktopConfiguration'
        'Test-HermesDesktopSettings'
        'Backup-HermesDesktopSettings'
        'Set-HermesDesktopSettings'
        'Restore-HermesDesktopSettings'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @('ProjectHermes', 'Windows', 'Desktop', 'Wallpaper', 'Configuration', 'Backup', 'Restore')
            ProjectUri = 'https://github.com/scott-renny/project-hermes'
            LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
            ReleaseNotes = 'Initial v0.5.0 native Windows desktop lifecycle.'
        }
    }
}
