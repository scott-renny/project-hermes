@{
    RootModule = 'Hermes.Developer.psm1'
    ModuleVersion = '0.6.0'
    GUID = '7f40d97a-b9c3-4c88-a2a5-87032b11922d'
    Author = 'Scott Renny'
    CompanyName = 'Project Hermes'
    Copyright = '(c) 2026 Scott Renny. All rights reserved.'
    Description = 'Provisions and validates the Project Hermes Windows developer environment.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-HermesDeveloperEnvironment'
        'Test-HermesDeveloperConfiguration'
        'Test-HermesDeveloperEnvironment'
        'Set-HermesDeveloperEnvironment'
        'Export-HermesDeveloperInventory'
        'Test-HermesRemoteHost'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{ PSData = @{
        Tags = @('ProjectHermes','Developer','OpenSSH','VSCode','WinGet','Validation')
        ProjectUri = 'https://github.com/scott-renny/project-hermes'
        LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes = 'Initial v0.6.0 developer-environment provisioning and validation contract.'
    }}
}
