Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.Maintenance'
$script:CoreManifest = Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'

if (-not (Test-Path -LiteralPath $script:CoreManifest -PathType Leaf)) {
    throw "Hermes.Core could not be found at '$script:CoreManifest'."
}

Import-Module -Name $script:CoreManifest -Force -ErrorAction Stop

$script:AuditCommands = @{
    Winget     = 'Test-HermesWingetPackages'
    Developer  = 'Test-HermesDeveloperEnvironment'
    Windows    = 'Test-HermesWindowsSettings'
    Explorer   = 'Test-HermesExplorerSettings'
    Taskbar    = 'Test-HermesTaskbarSettings'
    Desktop    = 'Test-HermesDesktopSettings'
    Terminal   = 'Test-HermesTerminalSettings'
    Git        = 'Test-HermesGitSettings'
    VSCode     = 'Test-HermesVSCodeSettings'
    PowerToys  = 'Test-HermesPowerToysSettings'
    PowerShell = 'Test-HermesPowerShellSettings'
}

function Get-HermesValue {
    param([object]$InputObject, [string]$Name)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [Collections.IDictionary]) {
        return $InputObject[$Name]
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertTo-HermesDifferenceList {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value)
}

function Resolve-HermesMaintenancePath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$PreferPrimaryWorktree
    )

    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }

    $repositoryRoot = Get-HermesRepositoryRoot

    if ($PreferPrimaryWorktree) {
        try {
            $commonDirectory = & git `
                -C $repositoryRoot `
                rev-parse `
                --path-format=absolute `
                --git-common-dir 2>$null

            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($commonDirectory)) {
                $primaryRoot = Split-Path ([string]$commonDirectory.Trim()) -Parent
                $primaryPath = [IO.Path]::GetFullPath((Join-Path $primaryRoot $Path))

                if (Test-Path -LiteralPath $primaryPath) {
                    return $primaryPath
                }
            }
        }
        catch {
            # Fall back to the active repository root below.
        }
    }

    return [IO.Path]::GetFullPath((Join-Path $repositoryRoot $Path))
}

function Test-HermesMaintenanceConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes the Hermes maintenance configuration.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $keys = if ($Configuration -is [Collections.IDictionary]) {
        @($Configuration.Keys)
    }
    else {
        @($Configuration.PSObject.Properties.Name)
    }

    $supported = @(
        'SchemaVersion'
        'ProfilePath'
        'BackupPolicy'
        'Reporting'
        'OperationalReferences'
    )

    foreach ($key in $keys | Where-Object { $_ -notin $supported }) {
        $errors.Add("Unsupported maintenance setting '$key'.")
    }

    $schemaVersion = [string](Get-HermesValue $Configuration 'SchemaVersion')
    if ($schemaVersion -ne '1.0') {
        $errors.Add("SchemaVersion must be '1.0'.")
    }

    $profilePath = [string](Get-HermesValue $Configuration 'ProfilePath')
    if ([string]::IsNullOrWhiteSpace($profilePath)) {
        $errors.Add('ProfilePath is required.')
    }

    $backupPolicy = Get-HermesValue $Configuration 'BackupPolicy'
    if ($null -eq $backupPolicy) {
        $errors.Add('BackupPolicy is required.')
        $backupPolicy = @{}
    }

    $maximumAgeDays = if ($null -ne (Get-HermesValue $backupPolicy 'MaximumAgeDays')) {
        [int](Get-HermesValue $backupPolicy 'MaximumAgeDays')
    }
    else { 30 }

    $minimumPerModule = if ($null -ne (Get-HermesValue $backupPolicy 'MinimumPerModule')) {
        [int](Get-HermesValue $backupPolicy 'MinimumPerModule')
    }
    else { 1 }

    if ($maximumAgeDays -lt 1) {
        $errors.Add('BackupPolicy.MaximumAgeDays must be at least 1.')
    }

    if ($minimumPerModule -lt 0) {
        $errors.Add('BackupPolicy.MinimumPerModule cannot be negative.')
    }

    $backupRoot = [string](Get-HermesValue $backupPolicy 'RootPath')
    if ([string]::IsNullOrWhiteSpace($backupRoot)) {
        $errors.Add('BackupPolicy.RootPath is required.')
    }

    $reporting = Get-HermesValue $Configuration 'Reporting'
    if ($null -eq $reporting) {
        $errors.Add('Reporting is required.')
        $reporting = @{}
    }

    $outputDirectory = [string](Get-HermesValue $reporting 'OutputDirectory')
    if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
        $errors.Add('Reporting.OutputDirectory is required.')
    }

    $formats = @((Get-HermesValue $reporting 'Formats') | ForEach-Object { [string]$_ })
    if ($formats.Count -eq 0) {
        $errors.Add('Reporting.Formats must contain at least one format.')
    }

    foreach ($format in $formats | Where-Object { $_ -notin @('Json', 'Markdown') }) {
        $errors.Add("Unsupported report format '$format'.")
    }

    $normalized = [ordered]@{
        SchemaVersion = '1.0'
        ProfilePath = $profilePath
        BackupPolicy = [ordered]@{
            RootPath = $backupRoot
            MaximumAgeDays = $maximumAgeDays
            MinimumPerModule = $minimumPerModule
            ValidateDocuments = [bool](Get-HermesValue $backupPolicy 'ValidateDocuments')
        }
        Reporting = [ordered]@{
            OutputDirectory = $outputDirectory
            Formats = @($formats | Select-Object -Unique)
        }
        OperationalReferences = Get-HermesValue $Configuration 'OperationalReferences'
    }

    [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
        Configuration = $normalized
    }
}

function Get-HermesBackupHealth {
    <#
    .SYNOPSIS
        Inventories Hermes backups and reports age and document-integrity problems.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [datetime]$ReferenceTime = (Get-Date)
    )

    $validation = Test-HermesMaintenanceConfiguration $Configuration
    if (-not $validation.IsValid) {
        throw ($validation.Errors -join [Environment]::NewLine)
    }

    $policy = $validation.Configuration.BackupPolicy
    $root = Resolve-HermesMaintenancePath `
        -Path $policy.RootPath `
        -PreferPrimaryWorktree
    $items = [Collections.Generic.List[object]]::new()
    $issues = [Collections.Generic.List[object]]::new()

    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        $issues.Add([pscustomobject]@{
            Category = 'BackupRoot'
            ModuleName = ''
            Path = $root
            Message = 'Backup root does not exist.'
        })
    }
    else {
        foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.json' -File -Recurse) {
            $document = $null
            $valid = $true
            $errorMessage = ''

            if ($policy.ValidateDocuments) {
                try {
                    $document = Read-HermesBackup -BackupPath $file.FullName
                }
                catch {
                    $valid = $false
                    $errorMessage = $_.Exception.Message
                }
            }

            $moduleName = if ($null -ne $document) {
                [string]$document.ModuleName
            }
            else {
                $file.Directory.Name
            }

            $createdAt = if ($null -ne $document) {
                [datetime]$document.CreatedAt
            }
            else {
                $file.LastWriteTime
            }

            $ageDays = [math]::Floor(($ReferenceTime - $createdAt).TotalDays)
            $stale = ($ageDays -gt $policy.MaximumAgeDays)

            $items.Add([pscustomobject]@{
                ModuleName = $moduleName
                Path = $file.FullName
                CreatedAt = $createdAt
                AgeDays = $ageDays
                Length = $file.Length
                IsValid = $valid
                IsStale = $stale
            })

            if (-not $valid) {
                $issues.Add([pscustomobject]@{
                    Category = 'InvalidDocument'
                    ModuleName = $moduleName
                    Path = $file.FullName
                    Message = $errorMessage
                })
            }
            elseif ($stale) {
                $issues.Add([pscustomobject]@{
                    Category = 'StaleBackup'
                    ModuleName = $moduleName
                    Path = $file.FullName
                    Message = "Backup is $ageDays days old."
                })
            }
        }

        foreach ($directory in Get-ChildItem -LiteralPath $root -Directory) {
        $count = @($items | Where-Object {
            (Split-Path (Split-Path $_.Path -Parent) -Leaf) -eq $directory.Name
        }).Count

            if ($count -lt $policy.MinimumPerModule) {
                $issues.Add([pscustomobject]@{
                    Category = 'InsufficientBackups'
                    ModuleName = $directory.Name
                    Path = $directory.FullName
                    Message = "Expected at least $($policy.MinimumPerModule) backup(s); found $count."
                })
            }
        }
    }

    [pscustomobject]@{
        CapturedAt = $ReferenceTime.ToString('o')
        RootPath = $root
        IsHealthy = ($issues.Count -eq 0)
        BackupCount = $items.Count
        ValidCount = @($items | Where-Object IsValid).Count
        StaleCount = @($items | Where-Object IsStale).Count
        Backups = @($items)
        Issues = @($issues)
    }
}

function Invoke-HermesWorkstationAudit {
    <#
    .SYNOPSIS
        Runs every enabled component compliance test in a Hermes workstation profile.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration)

    $validation = Test-HermesMaintenanceConfiguration $Configuration
    if (-not $validation.IsValid) {
        throw ($validation.Errors -join [Environment]::NewLine)
    }

    $profilePath = Resolve-HermesMaintenancePath $validation.Configuration.ProfilePath
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "The workstation profile '$profilePath' does not exist."
    }

    $repositoryRoot = Get-HermesRepositoryRoot
    $profile = Import-PowerShellDataFile -LiteralPath $profilePath
    $results = [Collections.Generic.List[object]]::new()

    foreach ($componentName in $profile.Order) {
        $component = $profile.Components[$componentName]
        if (-not [bool]$component.Enabled) { continue }

        $startedAt = Get-Date
        $status = 'Error'
        $isCompliant = $false
        $differences = @()
        $message = ''

        try {
            $modulePath = Join-Path $repositoryRoot $component.ModulePath
            $configurationPath = Join-Path $repositoryRoot $component.ConfigurationPath
            Import-Module -Name $modulePath -Force -ErrorAction Stop
            $desired = Import-PowerShellDataFile -LiteralPath $configurationPath
            $commandName = $script:AuditCommands[$componentName]

            if ([string]::IsNullOrWhiteSpace($commandName)) {
                throw "No audit command is registered for component '$componentName'."
            }

            $testResult = & $commandName -Configuration $desired
            $isCompliant = [bool](Get-HermesValue $testResult 'IsCompliant')
            $differencesValue = Get-HermesValue $testResult 'Differences'
            $differences = ConvertTo-HermesDifferenceList $differencesValue
            $status = if ($isCompliant) { 'Compliant' } else { 'Drifted' }
        }
        catch {
            $message = $_.Exception.Message
            if (-not [bool]$component.Required) {
                $status = 'Unavailable'
            }
        }

        $results.Add([pscustomobject]@{
            Component = $componentName
            Required = [bool]$component.Required
            Status = $status
            IsCompliant = $isCompliant
            DifferenceCount = @($differences).Count
            Differences = @($differences)
            Message = $message
            DurationMilliseconds = [math]::Round(((Get-Date) - $startedAt).TotalMilliseconds)
        })
    }

    $blocking = @($results | Where-Object {
        ($_.Required -and $_.Status -notin @('Compliant')) -or
        $_.Status -eq 'Drifted'
    })

    [pscustomobject]@{
        CapturedAt = (Get-Date).ToString('o')
        ProfileName = [string]$profile.Name
        IsCompliant = ($blocking.Count -eq 0)
        ComponentCount = $results.Count
        CompliantCount = @($results | Where-Object Status -EQ 'Compliant').Count
        DriftedCount = @($results | Where-Object Status -EQ 'Drifted').Count
        UnavailableCount = @($results | Where-Object Status -EQ 'Unavailable').Count
        ErrorCount = @($results | Where-Object Status -EQ 'Error').Count
        Components = @($results)
    }
}

function New-HermesMaintenanceReport {
    <#
    .SYNOPSIS
        Creates a consolidated maintenance report object.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [object]$Audit,
        [object]$BackupHealth
    )

    if (-not $PSBoundParameters.ContainsKey('Audit')) {
        $Audit = Invoke-HermesWorkstationAudit $Configuration
    }

    if (-not $PSBoundParameters.ContainsKey('BackupHealth')) {
        $BackupHealth = Get-HermesBackupHealth $Configuration
    }

    $validation = Test-HermesMaintenanceConfiguration $Configuration
    if (-not $validation.IsValid) {
        throw ($validation.Errors -join [Environment]::NewLine)
    }

    $healthy = ([bool]$Audit.IsCompliant -and [bool]$BackupHealth.IsHealthy)

    [pscustomobject]@{
        SchemaVersion = '1.0'
        ReportId = New-HermesGuid
        GeneratedAt = (Get-Date).ToString('o')
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        OverallStatus = if ($healthy) { 'Healthy' } else { 'AttentionRequired' }
        WorkstationAudit = $Audit
        BackupHealth = $BackupHealth
        OperationalReferences = $validation.Configuration.OperationalReferences
    }
}

function ConvertTo-HermesMaintenanceMarkdown {
    param([Parameter(Mandatory)][object]$Report)

    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('# Project Hermes Maintenance Report')
    $lines.Add('')
    $lines.Add("- Report ID: $($Report.ReportId)")
    $lines.Add("- Generated: $($Report.GeneratedAt)")
    $lines.Add("- Computer: $($Report.ComputerName)")
    $lines.Add("- Overall status: **$($Report.OverallStatus)**")
    $lines.Add('')
    $lines.Add('## Workstation audit')
    $lines.Add('')
    $lines.Add('| Component | Required | Status | Differences |')
    $lines.Add('|---|---:|---|---:|')

    foreach ($component in $Report.WorkstationAudit.Components) {
        $lines.Add("| $($component.Component) | $($component.Required) | $($component.Status) | $($component.DifferenceCount) |")
    }

    $lines.Add('')
    $lines.Add('## Backup health')
    $lines.Add('')
    $lines.Add("- Healthy: $($Report.BackupHealth.IsHealthy)")
    $lines.Add("- Backups: $($Report.BackupHealth.BackupCount)")
    $lines.Add("- Valid: $($Report.BackupHealth.ValidCount)")
    $lines.Add("- Stale: $($Report.BackupHealth.StaleCount)")
    $lines.Add('')
    $lines.Add('## Backup issues')
    $lines.Add('')

    if (@($Report.BackupHealth.Issues).Count -eq 0) {
        $lines.Add('No backup issues were detected.')
    }
    else {
        foreach ($issue in $Report.BackupHealth.Issues) {
            $lines.Add("- **$($issue.Category)** — $($issue.ModuleName): $($issue.Message)")
        }
    }

    return ($lines -join [Environment]::NewLine)
}

function Export-HermesMaintenanceReport {
    <#
    .SYNOPSIS
        Exports a consolidated maintenance report as UTF-8 JSON and Markdown.
    #>
    [CmdletBinding(SupportsShouldProcess)][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [Parameter(Mandatory)][object]$Report,
        [string]$OutputDirectory
    )

    $validation = Test-HermesMaintenanceConfiguration $Configuration
    if (-not $validation.IsValid) {
        throw ($validation.Errors -join [Environment]::NewLine)
    }

    $directory = if ($PSBoundParameters.ContainsKey('OutputDirectory')) {
        Resolve-HermesMaintenancePath $OutputDirectory
    }
    else {
        Resolve-HermesMaintenancePath $validation.Configuration.Reporting.OutputDirectory
    }

    $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $created = [Collections.Generic.List[string]]::new()

    if ($PSCmdlet.ShouldProcess($directory, 'Export Project Hermes maintenance report')) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        foreach ($format in $validation.Configuration.Reporting.Formats) {
            if ($format -eq 'Json') {
                $path = Join-Path $directory "Hermes-Maintenance-$timestamp.json"
                [IO.File]::WriteAllText(
                    $path,
                    ($Report | ConvertTo-Json -Depth 30),
                    [Text.UTF8Encoding]::new($false)
                )
                $created.Add($path)
            }
            elseif ($format -eq 'Markdown') {
                $path = Join-Path $directory "Hermes-Maintenance-$timestamp.md"
                [IO.File]::WriteAllText(
                    $path,
                    (ConvertTo-HermesMaintenanceMarkdown $Report),
                    [Text.UTF8Encoding]::new($false)
                )
                $created.Add($path)
            }
        }
    }

    [pscustomobject]@{
        OutputDirectory = $directory
        Created = @($created)
    }
}

Export-ModuleMember -Function @(
    'Test-HermesMaintenanceConfiguration'
    'Get-HermesBackupHealth'
    'Invoke-HermesWorkstationAudit'
    'New-HermesMaintenanceReport'
    'Export-HermesMaintenanceReport'
)
