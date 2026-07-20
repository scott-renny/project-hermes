@{
    RootModule='Hermes.Winget.psm1'
    ModuleVersion='0.5.0'
    GUID='a57fd76b-b375-4fc0-b43e-c30ecc6642bd'
    Author='Scott Renny'
    CompanyName='Project Hermes'
    Copyright='(c) Project Hermes'
    Description='Audits and installs approved Project Hermes WinGet package profiles.'
    PowerShellVersion='7.0'
    FunctionsToExport=@(
        'Get-HermesWingetPackages'
        'Test-HermesWingetConfiguration'
        'Test-HermesWingetPackages'
        'Export-HermesWingetInventory'
        'Install-HermesWingetPackages'
        'Get-HermesWingetUpgrades'
    )
    CmdletsToExport=@()
    VariablesToExport=@()
    AliasesToExport=@()
    PrivateData=@{PSData=@{Tags=@('Hermes','WinGet','Packages','Windows');ReleaseNotes='Initial Hermes.Winget package auditing and installation module.'}}
}
