@{
    RootModule = 'Hermes.PowerShell.psm1'
    ModuleVersion = '0.5.0'
    GUID = '416aa6dc-712e-4436-9e45-e4b9272ecb51'
    Author = 'Scott Renny'
    CompanyName = 'Project Hermes'
    Copyright = '(c) 2026 Scott Renny. All rights reserved.'
    Description = 'Safely manages the Project Hermes block in a PowerShell user profile.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-HermesPowerShellSettings'
        'Test-HermesPowerShellConfiguration'
        'Test-HermesPowerShellSettings'
        'Backup-HermesPowerShellSettings'
        'Set-HermesPowerShellSettings'
        'Restore-HermesPowerShellSettings'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{ PSData = @{
        Tags = @('ProjectHermes','PowerShell','Profile','Configuration','Backup','Restore')
        ProjectUri = 'https://github.com/scott-renny/project-hermes'
        LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes = 'Initial v0.5.0 PowerShell profile lifecycle.'
    }}
}
