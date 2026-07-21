@{
    RootModule = 'Hermes.Git.psm1'
    ModuleVersion = '0.5.0'
    GUID = 'a154554d-85ed-4d93-941a-dfa990317420'
    Author = 'Scott Renny'
    CompanyName = 'Project Hermes'
    Copyright = '(c) 2026 Scott Renny. All rights reserved.'
    Description = 'Safely manages selected user-level Git defaults for Project Hermes.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-HermesGitSettings'
        'Test-HermesGitConfiguration'
        'Test-HermesGitSettings'
        'Backup-HermesGitSettings'
        'Set-HermesGitSettings'
        'Restore-HermesGitSettings'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{ PSData = @{
        Tags = @('ProjectHermes','Git','Configuration','Backup','Restore')
        ProjectUri = 'https://github.com/scott-renny/project-hermes'
        LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes = 'Initial v0.5.0 user-level Git configuration lifecycle.'
    }}
}
