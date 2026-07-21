@{
    RootModule='Hermes.PowerToys.psm1'
    ModuleVersion='0.5.0'
    GUID='8bbd6868-ee16-43b8-aea4-f4347b8ccde3'
    Author='Scott Renny'
    CompanyName='Project Hermes'
    Copyright='(c) Project Hermes'
    Description='Manages a safe, reproducible PowerToys feature baseline for Project Hermes.'
    PowerShellVersion='7.0'
    FunctionsToExport=@(
        'Get-HermesPowerToysSettings'
        'Test-HermesPowerToysConfiguration'
        'Test-HermesPowerToysSettings'
        'Backup-HermesPowerToysSettings'
        'Set-HermesPowerToysSettings'
        'Restore-HermesPowerToysSettings'
    )
    CmdletsToExport=@()
    VariablesToExport=@()
    AliasesToExport=@()
    PrivateData=@{PSData=@{Tags=@('Hermes','PowerToys','Windows','Configuration');ReleaseNotes='Initial Hermes.PowerToys workstation configuration lifecycle.'}}
}
