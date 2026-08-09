BeforeAll {
    $script:RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $script:ManifestPath = Join-Path $PSScriptRoot '..\Hermes.Orchestration.psd1'
    $script:ConfigurationPath = Join-Path $script:RepositoryRoot 'configs\orchestration\hermes-orchestration-base.psd1'
    Import-Module $script:ManifestPath -Force
    $script:Configuration = Import-PowerShellDataFile $script:ConfigurationPath
}

Describe 'Hermes.Orchestration module contract' {
    It 'has a valid manifest' { Test-ModuleManifest $script:ManifestPath | Should -Not -BeNullOrEmpty }
    It 'uses version 0.9.0' { (Test-ModuleManifest $script:ManifestPath).Version.ToString() | Should -Be '0.9.0' }
    It 'exports exactly six commands' { @(Get-Command -Module Hermes.Orchestration).Count | Should -Be 6 }
    It 'provides help for every command' {
        Get-Command -Module Hermes.Orchestration | ForEach-Object {
            (Get-Help $_.Name).Synopsis | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes orchestration configuration' {
    It 'exists and validates' {
        $script:ConfigurationPath | Should -Exist
        (Test-HermesOrchestrationConfiguration $script:Configuration).IsValid | Should -BeTrue
    }
    It 'rejects unsupported settings' {
        $bad = $script:Configuration.Clone(); $bad.Unsupported = $true
        (Test-HermesOrchestrationConfiguration $bad).IsValid | Should -BeFalse
    }
    It 'rejects unsupported report formats' {
        $bad = $script:Configuration.Clone(); $bad.ReportFormats = @('Xml')
        (Test-HermesOrchestrationConfiguration $bad).IsValid | Should -BeFalse
    }
}

Describe 'Hermes orchestration planning' {
    It 'creates the complete ordered workstation plan' {
        $plan = Get-HermesOrchestrationPlan $script:Configuration
        $plan.ComponentCount | Should -Be 11
        $plan.Components.Component | Should -Be @('Winget','Developer','Windows','Explorer','Taskbar','Desktop','Terminal','Git','VSCode','PowerToys','PowerShell')
    }
    It 'supports selecting components while preserving profile order' {
        $plan = Get-HermesOrchestrationPlan $script:Configuration -Component @('PowerShell','Winget')
        $plan.Components.Component | Should -Be @('Winget','PowerShell')
    }
    It 'rejects an unknown component' {
        { Get-HermesOrchestrationPlan $script:Configuration -Component 'Unknown' } | Should -Throw '*Unknown workstation component*'
    }
    It 'preserves order and marks explicit exclusions' {
        $plan = Get-HermesOrchestrationPlan $script:Configuration -ExcludeComponent @('PowerShell','Terminal')
        $plan.ComponentCount | Should -Be 11
        $plan.ExcludedCount | Should -Be 2
        @($plan.Components | Where-Object Excluded).Component | Should -Be @('Terminal','PowerShell')
    }
    It 'rejects overlapping inclusion and exclusion' {
        { Get-HermesOrchestrationPlan $script:Configuration -Component 'Desktop' -ExcludeComponent 'Desktop' } |
            Should -Throw '*both included and excluded*'
    }
}

Describe 'Hermes orchestration elevation awareness' {
    It 'reports elevation state without failing user-scope preflight' {
        $preflight = Test-HermesOrchestrationPreflight $script:Configuration -Component 'Desktop'
        $preflight.IsElevated | Should -BeOfType [bool]
        $preflight.IsReady | Should -BeTrue
        $preflight.Components[0].Elevation | Should -Be 'CurrentUser'
    }
    It 'labels components that may request administrator approval' {
        $preflight = Test-HermesOrchestrationPreflight $script:Configuration -Component 'Winget'
        $preflight.Components[0].Elevation | Should -Be 'MayRequireAdministrator'
    }
}

Describe 'Hermes orchestration reporting' {
    It 'exports JSON and Markdown reports' {
        $output = Join-Path $TestDrive 'reports'
        $state = [pscustomobject]@{ RunId='test-run'; ProfileName='Test'; Mode='Audit'; IsSuccessful=$true; Results=@() }
        $result = Export-HermesOrchestrationReport -State $state -OutputDirectory $output -Confirm:$false
        $result.Created.Count | Should -Be 2
        $result.Created | ForEach-Object { $_ | Should -Exist }
    }
    It 'supports WhatIf without creating reports' {
        $output = Join-Path $TestDrive 'whatif'
        $state = [pscustomobject]@{ RunId='test-run'; ProfileName='Test'; Mode='Audit'; IsSuccessful=$true; Results=@() }
        Export-HermesOrchestrationReport -State $state -OutputDirectory $output -WhatIf | Out-Null
        $output | Should -Not -Exist
    }
}

Describe 'Hermes orchestration execution summary' {
    It 'keeps excluded components visible as skipped' {
        $state = Invoke-HermesWorkstation -Configuration $script:Configuration -Mode Audit -ExcludeComponent @('Terminal','VSCode','PowerToys')
        $state.ComponentCount | Should -Be 11
        $state.SkippedCount | Should -Be 3
        @($state.Results | Where-Object Status -eq 'Skipped').Component | Should -Be @('Terminal','VSCode','PowerToys')
        $state.FailureCount | Should -Be 0
        $state.IsElevated | Should -BeOfType [bool]
    }
    It 'distinguishes a successful audit from a compliant workstation' {
        $state = Invoke-HermesWorkstation -Configuration $script:Configuration -Mode Audit -Component @('Desktop','PowerShell')

        $state.IsSuccessful | Should -BeTrue
        $state.IsCompliant | Should -BeOfType [bool]
        $state.ComponentCount | Should -Be 2
        ($state.CompliantCount + $state.DriftedCount + $state.FailureCount) | Should -Be 2
    }

    It 'summarizes a WhatIf apply as planned without claiming compliance' {
        $state = Invoke-HermesWorkstation -Configuration $script:Configuration -Mode Apply -Component @('Desktop','PowerShell') -WhatIf

        $state.IsSuccessful | Should -BeTrue
        $state.IsCompliant | Should -BeFalse
        $state.PlannedCount | Should -Be 2
        $state.Results.Status | Should -Be @('Planned','Planned')
    }

    It 'persists a complete audit state that can be read back' {
        $statePath = Join-Path $TestDrive 'state\audit.json'
        $state = Invoke-HermesWorkstation -Configuration $script:Configuration -Mode Audit -Component @('Desktop','PowerShell') -StatePath $statePath
        $saved = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json

        $statePath | Should -Exist
        $saved.RunId | Should -Be $state.RunId
        $saved.ComponentCount | Should -Be 2
        $saved.Results.Count | Should -Be 2
        $saved.IsCompliant | Should -BeOfType [bool]
    }

    It 'does not write a state file during a WhatIf apply' {
        $statePath = Join-Path $TestDrive 'state\preview.json'
        Invoke-HermesWorkstation -Configuration $script:Configuration -Mode Apply -Component @('Desktop','PowerShell') -StatePath $statePath -WhatIf | Out-Null

        $statePath | Should -Not -Exist
    }
}

Describe 'Hermes orchestration resume behavior' {
    It 'returns an already completed state without starting another run' {
        $statePath = Join-Path $TestDrive 'completed.json'
        [pscustomobject]@{
            RunId = 'completed-run'
            Results = @(
                [pscustomobject]@{ Component='Desktop'; Status='Compliant' }
                [pscustomobject]@{ Component='PowerShell'; Status='Applied' }
            )
        } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statePath

        $result = Resume-HermesWorkstation -Configuration $script:Configuration -StatePath $statePath -Confirm:$false

        $result.RunId | Should -Be 'completed-run'
        $result.Results.Count | Should -Be 2
    }

    It 'does not resume an explicitly skipped component' {
        $statePath = Join-Path $TestDrive 'skipped.json'
        [pscustomobject]@{
            RunId = 'skipped-run'
            Results = @(
                [pscustomobject]@{ Component='Desktop'; Status='Compliant' }
                [pscustomobject]@{ Component='PowerShell'; Status='Skipped' }
            )
        } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statePath

        $result = Resume-HermesWorkstation -Configuration $script:Configuration -StatePath $statePath -Confirm:$false

        $result.RunId | Should -Be 'skipped-run'
    }

    It 'rejects a missing state file' {
        $missing = Join-Path $TestDrive 'missing.json'
        { Resume-HermesWorkstation -Configuration $script:Configuration -StatePath $missing -Confirm:$false } |
            Should -Throw '*Orchestration state not found*'
    }
}
