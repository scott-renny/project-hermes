@{
    RootModule = 'Hermes.Terminal.psm1'
    ModuleVersion = '0.5.0'
    GUID = 'a7d0df4d-c4ce-4d02-a119-f67969916f09'
    Author = 'Scott Renny'
    CompanyName = 'Project Hermes'
    Copyright = '(c) 2026 Scott Renny. All rights reserved.'
    Description = 'Safely manages the Project Hermes visual defaults in Windows Terminal settings.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-HermesTerminalSettings'
        'Test-HermesTerminalConfiguration'
        'Test-HermesTerminalSettings'
        'Backup-HermesTerminalSettings'
        'Set-HermesTerminalSettings'
        'Restore-HermesTerminalSettings'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{ PSData = @{
        Tags = @('ProjectHermes','WindowsTerminal','Configuration','Backup','Restore')
        ProjectUri = 'https://github.com/scott-renny/project-hermes'
        LicenseUri = 'https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes = 'Initial v0.5.0 Windows Terminal settings lifecycle.'
    }}
}
