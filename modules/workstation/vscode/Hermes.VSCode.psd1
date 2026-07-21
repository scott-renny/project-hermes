@{
    RootModule='Hermes.VSCode.psm1'; ModuleVersion='0.5.0'
    GUID='2e327813-8059-4a80-8b3f-af696267fd9d'
    Author='Scott Renny'; CompanyName='Project Hermes'
    Copyright='(c) 2026 Scott Renny. All rights reserved.'
    Description='Safely manages selected Visual Studio Code user settings for Project Hermes.'
    PowerShellVersion='7.0'
    FunctionsToExport=@(
        'Get-HermesVSCodeSettings','Test-HermesVSCodeConfiguration',
        'Test-HermesVSCodeSettings','Backup-HermesVSCodeSettings',
        'Set-HermesVSCodeSettings','Restore-HermesVSCodeSettings'
    )
    CmdletsToExport=@(); VariablesToExport=@(); AliasesToExport=@()
    PrivateData=@{PSData=@{
        Tags=@('ProjectHermes','VSCode','Configuration','Backup','Restore')
        ProjectUri='https://github.com/scott-renny/project-hermes'
        LicenseUri='https://github.com/scott-renny/project-hermes/blob/main/LICENSE'
        ReleaseNotes='Initial v0.5.0 VS Code user-settings lifecycle.'
    }}
}
