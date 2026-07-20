@{
    RootModule        = 'Hermes.Explorer.psm1'
    ModuleVersion     = '0.4.0'
    GUID              = '7f38eb69-7a94-44d8-92c6-fb3618b77e0e'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Manages, validates, backs up, applies, verifies, and restores Windows Explorer settings for Project Hermes.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Get-HermesExplorerSettings'
        'Test-HermesExplorerConfiguration'
        'Backup-HermesExplorerSettings'
        'Test-HermesExplorerSettings'
        'Set-HermesExplorerSettings'
        'Restore-HermesExplorerSettings'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('ProjectHermes', 'Windows', 'Explorer', 'Configuration', 'Backup', 'Restore')
            ProjectUri   = 'https://github.com/'
            ReleaseNotes = 'v0.4.0 implements verified Explorer restoration through Hermes.Core backups.'
        }
    }
}
