@{
    RootModule        = 'Hermes.Core.psm1'
    ModuleVersion     = '0.1.1'
    GUID              = 'f8bd2149-e1de-4681-94fc-df80a7ae4fc1'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Shared infrastructure and utilities for Project Hermes modules.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-HermesRepositoryRoot'
        'Get-HermesVersion'
        'New-HermesGuid'
        'Write-HermesBackup'
        'Read-HermesBackup'
    )

    CmdletsToExport    = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @(
                'Hermes'
                'ConfigurationManagement'
                'Backup'
                'Automation'
            )

            ProjectUri = 'https://github.com/'
        }
    }
}
