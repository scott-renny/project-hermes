@{
    RootModule        = 'Hermes.Taskbar.psm1'
    ModuleVersion     = '0.5.0'
    GUID              = 'c7bb477f-a762-4b0b-987f-d86cac211d76'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) 2026 Scott Renny. All rights reserved.'
    Description       = 'Reads, validates, backs up, applies, verifies, and restores Windows 11 taskbar settings.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-HermesTaskbarSettings'
        'Test-HermesTaskbarConfiguration'
        'Test-HermesTaskbarSettings'
        'Backup-HermesTaskbarSettings'
        'Set-HermesTaskbarSettings'
        'Restore-HermesTaskbarSettings'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @(
                'ProjectHermes'
                'Windows11'
                'Taskbar'
                'Configuration'
                'Backup'
                'Restore'
            )
            ProjectUri   = 'https://github.com/scott-renny/project-hermes'
            ReleaseNotes = 'Production rewrite with a canonical taskbar configuration model.'
        }
    }
}
