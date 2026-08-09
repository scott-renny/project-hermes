@{
    RootModule        = 'Hermes.Orchestration.psm1'
    ModuleVersion     = '0.9.0'
    GUID              = 'a434693e-b9c6-4aee-94d6-e20ec98743e8'
    Author            = 'Scott Renny'
    CompanyName       = 'Project Hermes'
    Copyright         = '(c) Project Hermes'
    Description       = 'Plans, validates, applies, resumes, and reports unified Project Hermes workstation orchestration.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Test-HermesOrchestrationConfiguration'
        'Get-HermesOrchestrationPlan'
        'Test-HermesOrchestrationPreflight'
        'Invoke-HermesWorkstation'
        'Resume-HermesWorkstation'
        'Export-HermesOrchestrationReport'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('ProjectHermes', 'Orchestration', 'Windows', 'Deployment', 'Recovery')
        }
    }
}
