@{
    RootModule        = 'Hermes.Windows.psm1'
    ModuleVersion     = '0.5.0'
    GUID              = '4d43e69d-6305-4ed8-9b77-74d38e60db46'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Manages, validates, backs up, applies, verifies, and restores supported Windows personalization settings for Project Hermes.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-HermesWindowsSettings'
        'Test-HermesWindowsConfiguration'
        'Test-HermesWindowsSettings'
        'Backup-HermesWindowsSettings'
        'Set-HermesWindowsSettings'
        'Restore-HermesWindowsSettings'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @(
                'ProjectHermes'
                'Windows'
                'Personalization'
                'Configuration'
                'Backup'
                'Restore'
            )
            ProjectUri = 'https://github.com/scott-renny/project-hermes'
            LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
            ReleaseNotes = 'Initial v0.5.0 Windows personalization lifecycle.'
        }
    }
}
