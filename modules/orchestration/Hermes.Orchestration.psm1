Set-StrictMode -Version Latest

$script:ComponentCommands = [ordered]@{
    Winget     = @{ Validate = 'Test-HermesWingetConfiguration'; Test = 'Test-HermesWingetPackages'; Set = 'Install-HermesWingetPackages' }
    Developer  = @{ Validate = 'Test-HermesDeveloperConfiguration'; Test = 'Test-HermesDeveloperEnvironment'; Set = 'Set-HermesDeveloperEnvironment' }
    Windows    = @{ Validate = 'Test-HermesWindowsConfiguration'; Test = 'Test-HermesWindowsSettings'; Set = 'Set-HermesWindowsSettings' }
    Explorer   = @{ Validate = 'Test-HermesExplorerConfiguration'; Test = 'Test-HermesExplorerSettings'; Set = 'Set-HermesExplorerSettings' }
    Taskbar    = @{ Validate = 'Test-HermesTaskbarConfiguration'; Test = 'Test-HermesTaskbarSettings'; Set = 'Set-HermesTaskbarSettings' }
    Desktop    = @{ Validate = 'Test-HermesDesktopConfiguration'; Test = 'Test-HermesDesktopSettings'; Set = 'Set-HermesDesktopSettings' }
    Terminal   = @{ Validate = 'Test-HermesTerminalConfiguration'; Test = 'Test-HermesTerminalSettings'; Set = 'Set-HermesTerminalSettings' }
    Git        = @{ Validate = 'Test-HermesGitConfiguration'; Test = 'Test-HermesGitSettings'; Set = 'Set-HermesGitSettings' }
    VSCode     = @{ Validate = 'Test-HermesVSCodeConfiguration'; Test = 'Test-HermesVSCodeSettings'; Set = 'Set-HermesVSCodeSettings' }
    PowerToys  = @{ Validate = 'Test-HermesPowerToysConfiguration'; Test = 'Test-HermesPowerToysSettings'; Set = 'Set-HermesPowerToysSettings' }
    PowerShell = @{ Validate = 'Test-HermesPowerShellConfiguration'; Test = 'Test-HermesPowerShellSettings'; Set = 'Set-HermesPowerShellSettings' }
}

function Get-HermesOrchestrationRepositoryRoot {
    [CmdletBinding()]
    param()
    (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
}

function ConvertTo-HermesOrchestrationArray {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return @() }
    @($Value)
}

function Test-HermesOrchestrationConfiguration {
    <# .SYNOPSIS Validates a Project Hermes orchestration configuration. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [System.Collections.IDictionary]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $allowed = @('SchemaVersion', 'ProfilePath', 'StateDirectory', 'StopOnRequiredFailure', 'ContinueOptionalFailures', 'ReportFormats')
    foreach ($key in $Configuration.Keys) {
        if ($key -notin $allowed) { $errors.Add("Unsupported orchestration setting '$key'.") }
    }
    foreach ($required in @('SchemaVersion', 'ProfilePath', 'StateDirectory', 'StopOnRequiredFailure', 'ContinueOptionalFailures', 'ReportFormats')) {
        if (-not $Configuration.Contains($required)) { $errors.Add("Missing orchestration setting '$required'.") }
    }
    if ($Configuration.SchemaVersion -ne '1.0') { $errors.Add("Unsupported schema version '$($Configuration.SchemaVersion)'.") }
    if ([string]::IsNullOrWhiteSpace([string]$Configuration.ProfilePath)) { $errors.Add('ProfilePath cannot be empty.') }
    if ([string]::IsNullOrWhiteSpace([string]$Configuration.StateDirectory)) { $errors.Add('StateDirectory cannot be empty.') }
    foreach ($name in @('StopOnRequiredFailure', 'ContinueOptionalFailures')) {
        if ($Configuration.Contains($name) -and $Configuration[$name] -isnot [bool]) { $errors.Add("$name must be Boolean.") }
    }
    $formats = @(ConvertTo-HermesOrchestrationArray $Configuration.ReportFormats)
    if ($formats.Count -eq 0) { $errors.Add('At least one report format is required.') }
    foreach ($format in $formats) {
        if ($format -notin @('Json', 'Markdown')) { $errors.Add("Unsupported report format '$format'.") }
    }

    [pscustomobject]@{
        IsValid       = $errors.Count -eq 0
        Errors        = $errors.ToArray()
        Configuration = $Configuration
    }
}

function Get-HermesOrchestrationPlan {
    <# .SYNOPSIS Creates an ordered execution plan from a unified workstation profile. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [System.Collections.IDictionary]$Configuration,
        [string[]]$Component
    )

    $validation = Test-HermesOrchestrationConfiguration -Configuration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join [Environment]::NewLine) }

    $root = Get-HermesOrchestrationRepositoryRoot
    $profilePath = Join-Path $root $Configuration.ProfilePath
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) { throw "Workstation profile not found: $profilePath" }
    $profile = Import-PowerShellDataFile -LiteralPath $profilePath
    $selected = if ($Component) { @($Component) } else { @($profile.Order) }

    foreach ($name in $selected) {
        if ($name -notin $profile.Order) { throw "Unknown workstation component '$name'." }
    }

    $position = 0
    $items = foreach ($name in $profile.Order) {
        if ($name -notin $selected) { continue }
        $definition = $profile.Components[$name]
        if (-not $definition.Enabled) { continue }
        $position++
        $modulePath = Join-Path $root $definition.ModulePath
        $configurationPath = Join-Path $root $definition.ConfigurationPath
        [pscustomobject]@{
            Position          = $position
            Component         = $name
            Required          = [bool]$definition.Required
            ModulePath        = $modulePath
            ConfigurationPath = $configurationPath
            Commands          = [pscustomobject]$script:ComponentCommands[$name]
        }
    }

    [pscustomobject]@{
        SchemaVersion = '1.0'
        ProfileName   = $profile.Name
        RepositoryRoot = $root
        ComponentCount = @($items).Count
        Components    = @($items)
    }
}

function Test-HermesOrchestrationPreflight {
    <# .SYNOPSIS Validates platform, files, module contracts, and component configurations before orchestration. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [System.Collections.IDictionary]$Configuration,
        [string[]]$Component
    )

    $plan = Get-HermesOrchestrationPlan -Configuration $Configuration -Component $Component
    $results = foreach ($item in $plan.Components) {
        $issues = [Collections.Generic.List[string]]::new()
        if (-not (Test-Path -LiteralPath $item.ModulePath -PathType Leaf)) { $issues.Add("Module not found: $($item.ModulePath)") }
        if (-not (Test-Path -LiteralPath $item.ConfigurationPath -PathType Leaf)) { $issues.Add("Configuration not found: $($item.ConfigurationPath)") }
        if ($issues.Count -eq 0) {
            try {
                Import-Module -Name $item.ModulePath -Force -ErrorAction Stop
                $componentConfiguration = Import-PowerShellDataFile -LiteralPath $item.ConfigurationPath
                foreach ($commandName in @($item.Commands.Validate, $item.Commands.Test, $item.Commands.Set)) {
                    if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) { $issues.Add("Command not exported: $commandName") }
                }
                if ($issues.Count -eq 0) {
                    $configurationResult = & $item.Commands.Validate -Configuration $componentConfiguration
                    if (-not $configurationResult.IsValid) { $issues.Add(($configurationResult.Errors -join '; ')) }
                }
            }
            catch { $issues.Add($_.Exception.Message) }
        }
        [pscustomobject]@{
            Component = $item.Component
            Required   = $item.Required
            IsReady    = $issues.Count -eq 0
            Issues     = $issues.ToArray()
        }
    }

    [pscustomobject]@{
        IsReady    = @($results | Where-Object { $_.Required -and -not $_.IsReady }).Count -eq 0
        Plan       = $plan
        Components = @($results)
    }
}

function Save-HermesOrchestrationState {
    param([Parameter(Mandatory)]$State, [Parameter(Mandatory)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent) { [IO.Directory]::CreateDirectory($parent) | Out-Null }
    $State | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Invoke-HermesWorkstation {
    <# .SYNOPSIS Audits or applies a unified Project Hermes workstation profile in dependency order. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)] [System.Collections.IDictionary]$Configuration,
        [ValidateSet('Audit', 'Apply')] [string]$Mode = 'Audit',
        [string[]]$Component,
        [string]$StatePath
    )

    $started = Get-Date
    $preflight = Test-HermesOrchestrationPreflight -Configuration $Configuration -Component $Component
    if (-not $preflight.IsReady) {
        $requiredIssues = $preflight.Components | Where-Object { $_.Required -and -not $_.IsReady }
        throw "Required preflight checks failed: $($requiredIssues.Component -join ', ')"
    }

    $results = [Collections.Generic.List[object]]::new()
    foreach ($item in $preflight.Plan.Components) {
        $ready = $preflight.Components | Where-Object Component -eq $item.Component
        if (-not $ready.IsReady) {
            $results.Add([pscustomobject]@{ Component=$item.Component; Required=$item.Required; Status='Unavailable'; IsCompliant=$false; Message=($ready.Issues -join '; ') })
            continue
        }

        try {
            Import-Module -Name $item.ModulePath -Force -ErrorAction Stop
            $componentConfiguration = Import-PowerShellDataFile -LiteralPath $item.ConfigurationPath
            $before = & $item.Commands.Test -Configuration $componentConfiguration
            if ($before.IsCompliant) {
                $status = 'Compliant'
                $after = $before
            }
            elseif ($Mode -eq 'Audit') {
                $status = 'Drifted'
                $after = $before
            }
            elseif ($PSCmdlet.ShouldProcess($item.Component, "Apply Project Hermes component using $($item.Commands.Set)")) {
                & $item.Commands.Set -Configuration $componentConfiguration -Confirm:$false | Out-Null
                $after = & $item.Commands.Test -Configuration $componentConfiguration
                $status = if ($after.IsCompliant) { 'Applied' } else { 'VerificationFailed' }
            }
            else {
                $status = 'Planned'
                $after = $before
            }
            $results.Add([pscustomobject]@{ Component=$item.Component; Required=$item.Required; Status=$status; IsCompliant=[bool]$after.IsCompliant; Message='' })
        }
        catch {
            $results.Add([pscustomobject]@{ Component=$item.Component; Required=$item.Required; Status='Failed'; IsCompliant=$false; Message=$_.Exception.Message })
            if ($item.Required -and $Configuration.StopOnRequiredFailure) { break }
            if (-not $item.Required -and -not $Configuration.ContinueOptionalFailures) { break }
        }
    }

    $resultArray = $results.ToArray()
    $compliantCount = @($resultArray | Where-Object IsCompliant).Count
    $requiredFailureCount = @(
        $resultArray | Where-Object {
            $_.Required -and $_.Status -in @('Failed','Unavailable','VerificationFailed')
        }
    ).Count

    $state = [pscustomobject]@{
        SchemaVersion = '1.0'
        RunId = [guid]::NewGuid().ToString()
        Mode = $Mode
        ProfileName = $preflight.Plan.ProfileName
        StartedAt = $started.ToString('o')
        CompletedAt = (Get-Date).ToString('o')
        IsSuccessful = $requiredFailureCount -eq 0
        IsCompliant = $compliantCount -eq $resultArray.Count
        ComponentCount = $resultArray.Count
        CompliantCount = $compliantCount
        DriftedCount = @($resultArray | Where-Object Status -eq 'Drifted').Count
        PlannedCount = @($resultArray | Where-Object Status -eq 'Planned').Count
        FailureCount = @($resultArray | Where-Object Status -in @('Failed','Unavailable','VerificationFailed')).Count
        Results = $resultArray
    }
    if ($StatePath -and -not $WhatIfPreference) {
        Save-HermesOrchestrationState -State $state -Path $StatePath
    }
    $state
}

function Resume-HermesWorkstation {
    <# .SYNOPSIS Resumes a workstation run by selecting components that were not completed successfully. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)] [System.Collections.IDictionary]$Configuration,
        [Parameter(Mandatory)] [string]$StatePath
    )
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { throw "Orchestration state not found: $StatePath" }
    $previous = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    $remaining = @($previous.Results | Where-Object Status -notin @('Compliant','Applied') | Select-Object -ExpandProperty Component)
    if ($remaining.Count -eq 0) { return $previous }
    $invokeParameters = @{
        Configuration = $Configuration
        Mode = 'Apply'
        Component = $remaining
        StatePath = $StatePath
        Confirm = $false
    }
    if ($WhatIfPreference) { $invokeParameters.WhatIf = $true }
    Invoke-HermesWorkstation @invokeParameters
}

function Export-HermesOrchestrationReport {
    <# .SYNOPSIS Exports a completed orchestration state as JSON and Markdown. #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$OutputDirectory
    )
    $created = [Collections.Generic.List[string]]::new()
    if ($PSCmdlet.ShouldProcess($OutputDirectory, 'Export Project Hermes orchestration report')) {
        [IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
        $base = "Hermes-Orchestration-$($State.RunId)"
        $jsonPath = Join-Path $OutputDirectory "$base.json"
        $markdownPath = Join-Path $OutputDirectory "$base.md"
        $State | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding utf8NoBOM
        $lines = @(
            '# Project Hermes Orchestration Report', '',
            "- Run ID: $($State.RunId)", "- Profile: $($State.ProfileName)",
            "- Mode: $($State.Mode)", "- Successful: $($State.IsSuccessful)", '',
            '| Component | Required | Status | Compliant | Message |',
            '|---|---:|---|---:|---|'
        )
        foreach ($result in $State.Results) {
            $message = ([string]$result.Message).Replace('|', '\|')
            $lines += "| $($result.Component) | $($result.Required) | $($result.Status) | $($result.IsCompliant) | $message |"
        }
        $lines | Set-Content -LiteralPath $markdownPath -Encoding utf8NoBOM
        $created.Add($jsonPath); $created.Add($markdownPath)
    }
    [pscustomobject]@{ OutputDirectory=$OutputDirectory; Created=$created.ToArray() }
}

Export-ModuleMember -Function @(
    'Test-HermesOrchestrationConfiguration', 'Get-HermesOrchestrationPlan',
    'Test-HermesOrchestrationPreflight', 'Invoke-HermesWorkstation',
    'Resume-HermesWorkstation', 'Export-HermesOrchestrationReport'
)
