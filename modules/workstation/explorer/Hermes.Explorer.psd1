@{
    RootModule        = 'Hermes.Explorer.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = '1096a194-e926-424b-81e1-e30289199360'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Project Hermes module for Windows Explorer configuration management.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-HermesExplorerSettings'
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
            Tags = @(
                'Hermes'
                'Explorer'
                'Windows'
                'ConfigurationManagement'
            )

            ProjectUri = 'https://github.com/'
        }
    }
}
