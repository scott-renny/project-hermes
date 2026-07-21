@{
    RootModule        = 'Hermes.Common.psm1'
    ModuleVersion     = '0.1.0'

    GUID              = '87ed7e34-d5da-44b4-8f63-73c37ab6fc98'

    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) Project Hermes'

    Description       = 'Shared helper module used by every Project Hermes module.'

    PowerShellVersion = '5.1'

    CompatiblePSEditions = @(
        'Desktop'
        'Core'
    )

    FunctionsToExport = @(
        'Write-HermesLog'
        'Write-HermesSuccess'
        'Write-HermesWarning'
        'Write-HermesError'

        'Test-HermesAdministrator'
        'Test-HermesOperatingSystem'
        'Test-HermesPowerShell'

        'Test-HermesRegistryPath'
        'Get-HermesRegistryValue'
        'Set-HermesRegistryValue'
        'Remove-HermesRegistryValue'

        'Restart-HermesExplorer'

        'Export-HermesJson'
        'Import-HermesJson'
    )

    CmdletsToExport = @()

    VariablesToExport = @()

    AliasesToExport = @()

    PrivateData = @{

        PSData = @{

            Tags = @(
                'Hermes'
                'Automation'
                'Windows'
                'PowerShell'
            )

            ProjectUri = ''
            LicenseUri = ''

            ReleaseNotes = 'Initial Hermes.Common module.'
        }
    }
}