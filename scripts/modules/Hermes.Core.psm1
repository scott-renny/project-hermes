Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-HermesWindows {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return $true
    }

    return [bool]$IsWindows
}

function Test-HermesAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-HermesContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string]$ScriptVersion,

        [Parameter(Mandatory)]
        [int]$WingetTimeoutSeconds,

        [Parameter()]
        [bool]$SkipWinget,

        [Parameter()]
        [bool]$Resume,

        [Parameter()]
        [bool]$Force
    )

    $resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    $runTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $runId = "initialize-$runTimestamp"

    [pscustomobject]@{
        ProjectRoot          = $resolvedRoot
        ScriptVersion        = $ScriptVersion
        RunTimestamp         = $runTimestamp
        RunId                = $runId
        LogDirectory         = Join-Path $resolvedRoot "logs"
        LogFile              = Join-Path $resolvedRoot "logs\$runId.log"
        StateDirectory       = Join-Path $resolvedRoot "exports\state"
        StateFile            = Join-Path $resolvedRoot "exports\state\$runId.json"
        LatestStateFile      = Join-Path $resolvedRoot "exports\state\latest.json"
        SummaryDirectory     = Join-Path $resolvedRoot "exports\summaries"
        SummaryFile          = Join-Path $resolvedRoot "exports\summaries\$runId.json"
        BaselineRoot         = Join-Path $resolvedRoot "exports\baseline\$runTimestamp"
        WingetTimeoutSeconds = $WingetTimeoutSeconds
        SkipWinget           = $SkipWinget
        Resume               = $Resume
        Force                = $Force
        IsAdministrator      = Test-HermesAdministrator
        StartedAt            = Get-Date
        CompletedAt          = $null
        Results              = [System.Collections.Generic.List[object]]::new()
    }
}

function Write-HermesLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context,

        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "WARNING" { Write-Host $line -ForegroundColor Yellow }
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        default   { Write-Host $line }
    }

    if (-not (Test-Path -LiteralPath $Context.LogDirectory -PathType Container)) {
        [System.IO.Directory]::CreateDirectory($Context.LogDirectory) | Out-Null
    }

    Add-Content -LiteralPath $Context.LogFile -Value $line -Encoding UTF8
}

function Add-HermesResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context,

        [Parameter(Mandatory)]
        [string]$Step,

        [ValidateSet("Succeeded", "Warning", "Skipped", "Failed")]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$OutputPath
    )

    $result = [pscustomobject]@{
        Timestamp  = (Get-Date).ToString("o")
        Step       = $Step
        Status     = $Status
        Message    = $Message
        OutputPath = $OutputPath
    }

    $Context.Results.Add($result)

    $level = switch ($Status) {
        "Succeeded" { "SUCCESS" }
        "Warning"   { "WARNING" }
        "Skipped"   { "WARNING" }
        "Failed"    { "ERROR" }
    }

    Write-HermesLog -Context $Context -Message "${Step}: $Message" -Level $level
    Save-HermesState -Context $Context
}

function Save-HermesState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )

    [System.IO.Directory]::CreateDirectory($Context.StateDirectory) | Out-Null

    $state = [ordered]@{
        Project           = "Project Hermes"
        RunId             = $Context.RunId
        ScriptVersion     = $Context.ScriptVersion
        ProjectRoot       = $Context.ProjectRoot
        StartedAt         = $Context.StartedAt.ToString("o")
        UpdatedAt         = (Get-Date).ToString("o")
        IsAdministrator   = $Context.IsAdministrator
        Results           = @($Context.Results)
    }

    $json = $state | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $Context.StateFile -Value $json -Encoding UTF8
    Set-Content -LiteralPath $Context.LatestStateFile -Value $json -Encoding UTF8
}

function Start-HermesRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )

    if (-not (Test-HermesWindows)) {
        throw "Project Hermes initialization must be run on Windows."
    }

    [System.IO.Directory]::CreateDirectory($Context.ProjectRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($Context.LogDirectory) | Out-Null
    [System.IO.File]::WriteAllText($Context.LogFile, "", [System.Text.UTF8Encoding]::new($false))

    Write-HermesLog -Context $Context -Message "Starting Project Hermes initialization."
    Write-HermesLog -Context $Context -Message "Script version: $($Context.ScriptVersion)"
    Write-HermesLog -Context $Context -Message "Project root: $($Context.ProjectRoot)"
    Write-HermesLog -Context $Context -Message "Running as Administrator: $($Context.IsAdministrator)"

    if ($Context.Resume) {
        Write-HermesLog -Context $Context -Message "Resume mode enabled."
    }

    Save-HermesState -Context $Context
}

function Initialize-HermesRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )

    $directories = @(
        "assets",
        "configs",
        "configs\powershell",
        "configs\terminal",
        "configs\vscode",
        "configs\rainmeter",
        "configs\windhawk",
        "configs\windows",
        "docs",
        "docs\planning",
        "docs\implementation",
        "docs\reference",
        "docs\screenshots",
        "exports",
        "exports\baseline",
        "exports\state",
        "exports\summaries",
        "logs",
        "scripts",
        "scripts\automation",
        "scripts\backups",
        "scripts\bootstrap",
        "scripts\diagnostics",
        "scripts\maintenance",
        "scripts\modules",
        "themes"
    )

    foreach ($directory in $directories) {
        $path = Join-Path $Context.ProjectRoot $directory
        $existed = Test-Path -LiteralPath $path -PathType Container
        [System.IO.Directory]::CreateDirectory($path) | Out-Null

        if ($existed) {
            Write-HermesLog -Context $Context -Message "Directory already exists: $path"
        }
        else {
            Write-HermesLog -Context $Context -Message "Created directory: $path"
        }
    }

    Add-HermesResult -Context $Context -Step "Repository structure" -Status "Succeeded" -Message "Repository structure is ready."
}

function Test-HermesStepCompleted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context,

        [Parameter(Mandatory)]
        [string]$Step
    )

    if (-not $Context.Resume) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $Context.LatestStateFile -PathType Leaf)) {
        return $false
    }

    try {
        $previous = Get-Content -LiteralPath $Context.LatestStateFile -Raw | ConvertFrom-Json
        return [bool]($previous.Results | Where-Object {
            $_.Step -eq $Step -and $_.Status -eq "Succeeded"
        })
    }
    catch {
        return $false
    }
}

function Invoke-HermesExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context,

        [Parameter(Mandatory)]
        [string]$Step,

        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [ValidateSet("Csv", "Json", "Text", "Clixml")]
        [string]$Format = "Csv",

        [switch]$RequiresAdministrator
    )

    if (Test-HermesStepCompleted -Context $Context -Step $Step) {
        Add-HermesResult -Context $Context -Step $Step -Status "Skipped" -Message "Already completed in the previous run." -OutputPath $OutputPath
        return
    }

    if ($RequiresAdministrator -and -not $Context.IsAdministrator) {
        Add-HermesResult -Context $Context -Step $Step -Status "Skipped" -Message "Administrator privileges are required." -OutputPath $OutputPath
        return
    }

    try {
        Write-HermesLog -Context $Context -Message "Running step: $Step"

        $result = & $Command

        switch ($Format) {
            "Csv" {
                @($result) | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "Json" {
                @($result) | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            "Text" {
                @($result) | Out-String -Width 240 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            "Clixml" {
                @($result) | Export-Clixml -LiteralPath $OutputPath
            }
        }

        Add-HermesResult -Context $Context -Step $Step -Status "Succeeded" -Message "Export completed." -OutputPath $OutputPath
    }
    catch {
        Add-HermesResult -Context $Context -Step $Step -Status "Warning" -Message $_.Exception.Message -OutputPath $OutputPath
    }
}

function Get-HermesInstalledPrograms {
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $programs = foreach ($registryPath in $registryPaths) {
        Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue |
            ForEach-Object {
                $displayNameProperty = $_.PSObject.Properties["DisplayName"]

                if ($null -ne $displayNameProperty -and
                    -not [string]::IsNullOrWhiteSpace([string]$displayNameProperty.Value)) {

                    $displayVersionProperty = $_.PSObject.Properties["DisplayVersion"]
                    $publisherProperty = $_.PSObject.Properties["Publisher"]
                    $installDateProperty = $_.PSObject.Properties["InstallDate"]
                    $installLocationProperty = $_.PSObject.Properties["InstallLocation"]

                    [pscustomobject]@{
                        DisplayName     = [string]$displayNameProperty.Value
                        DisplayVersion  = if ($null -ne $displayVersionProperty) { [string]$displayVersionProperty.Value } else { $null }
                        Publisher       = if ($null -ne $publisherProperty) { [string]$publisherProperty.Value } else { $null }
                        InstallDate     = if ($null -ne $installDateProperty) { [string]$installDateProperty.Value } else { $null }
                        InstallLocation = if ($null -ne $installLocationProperty) { [string]$installLocationProperty.Value } else { $null }
                        RegistryPath    = [string]$_.PSPath
                    }
                }
            }
    }

    $programs | Sort-Object DisplayName, DisplayVersion -Unique
}

function Invoke-HermesWingetInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )

    $step = "Winget packages"
    $outputPath = Join-Path $Context.BaselineRoot "winget-packages.txt"
    $errorPath = Join-Path $Context.BaselineRoot "winget-packages-error.txt"

    if ($Context.SkipWinget) {
        Add-HermesResult -Context $Context -Step $step -Status "Skipped" -Message "Skipped by request." -OutputPath $outputPath
        return
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Add-HermesResult -Context $Context -Step $step -Status "Skipped" -Message "Winget is not installed or unavailable." -OutputPath $outputPath
        return
    }

    try {
        Write-HermesLog -Context $Context -Message "Running step: $step (timeout: $($Context.WingetTimeoutSeconds) seconds)"

        $process = Start-Process `
            -FilePath "winget.exe" `
            -ArgumentList @("list", "--disable-interactivity", "--accept-source-agreements") `
            -RedirectStandardOutput $outputPath `
            -RedirectStandardError $errorPath `
            -PassThru `
            -WindowStyle Hidden

        if (-not $process.WaitForExit($Context.WingetTimeoutSeconds * 1000)) {
            try {
                $process.Kill()
            }
            catch {
            }

            Add-HermesResult -Context $Context -Step $step -Status "Warning" -Message "Winget inventory timed out; baseline collection continued." -OutputPath $outputPath
            return
        }

        if ($process.ExitCode -eq 0) {
            if ((Test-Path -LiteralPath $errorPath) -and ((Get-Item -LiteralPath $errorPath).Length -eq 0)) {
                Remove-Item -LiteralPath $errorPath -Force
            }

            Add-HermesResult -Context $Context -Step $step -Status "Succeeded" -Message "Export completed." -OutputPath $outputPath
        }
        else {
            Add-HermesResult -Context $Context -Step $step -Status "Warning" -Message "Winget exited with code $($process.ExitCode)." -OutputPath $outputPath
        }
    }
    catch {
        Add-HermesResult -Context $Context -Step $step -Status "Warning" -Message $_.Exception.Message -OutputPath $outputPath
    }
}

function Invoke-HermesBaseline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context
    )

    [System.IO.Directory]::CreateDirectory($Context.BaselineRoot) | Out-Null
    Write-HermesLog -Context $Context -Message "Collecting system baseline into: $($Context.BaselineRoot)"

    $exports = @(
        @{ Step = "Computer information"; File = "computer-info.json"; Format = "Json"; Command = { Get-ComputerInfo } },
        @{ Step = "Computer system"; File = "computer-system.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_ComputerSystem } },
        @{ Step = "BIOS"; File = "bios.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_BIOS } },
        @{ Step = "Processors"; File = "processors.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_Processor } },
        @{ Step = "Memory modules"; File = "memory-modules.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_PhysicalMemory } },
        @{ Step = "Disk drives"; File = "disk-drives.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_DiskDrive } },
        @{ Step = "Volumes"; File = "volumes.csv"; Format = "Csv"; Command = { Get-Volume } },
        @{ Step = "Network adapters"; File = "network-adapters.csv"; Format = "Csv"; Command = { Get-NetAdapter } },
        @{ Step = "Network configuration"; File = "network-configuration.txt"; Format = "Text"; Command = { Get-NetIPConfiguration } },
        @{ Step = "Drivers"; File = "drivers.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_PnPSignedDriver } },
        @{ Step = "Installed programs"; File = "installed-programs.csv"; Format = "Csv"; Command = { Get-HermesInstalledPrograms } },
        @{ Step = "AppX packages"; File = "appx-packages.csv"; Format = "Csv"; Command = { Get-AppxPackage | Select-Object Name, Version, Publisher } },
        @{ Step = "Startup items"; File = "startup-items.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_StartupCommand } },
        @{ Step = "Services"; File = "services.csv"; Format = "Csv"; Command = { Get-Service | Select-Object Name, DisplayName, Status, StartType } },
        @{ Step = "Scheduled tasks"; File = "scheduled-tasks.csv"; Format = "Csv"; Command = { Get-ScheduledTask | Select-Object TaskPath, TaskName, State, Author } },
        @{ Step = "Environment variables"; File = "environment-variables.csv"; Format = "Csv"; Command = { Get-ChildItem Env: | Sort-Object Name } },
        @{ Step = "PowerShell version"; File = "powershell-version.txt"; Format = "Text"; Command = { $PSVersionTable } },
        @{ Step = "Windows optional features"; File = "windows-features.csv"; Format = "Csv"; RequiresAdministrator = $true; Command = { Get-WindowsOptionalFeature -Online | Select-Object FeatureName, State } },
        @{ Step = "Monitors"; File = "monitors.csv"; Format = "Csv"; Command = { Get-CimInstance Win32_DesktopMonitor | Select-Object Name, ScreenHeight, ScreenWidth, Status } }
    )

    foreach ($export in $exports) {
        $parameters = @{
            Context    = $Context
            Step       = $export.Step
            Command    = $export.Command
            OutputPath = Join-Path $Context.BaselineRoot $export.File
            Format     = $export.Format
        }

        if ($export.ContainsKey("RequiresAdministrator")) {
            $parameters.RequiresAdministrator = [bool]$export.RequiresAdministrator
        }

        Invoke-HermesExport @parameters
    }

    Invoke-HermesWingetInventory -Context $Context

    $operatingSystem = Get-CimInstance Win32_OperatingSystem
    $baselineSummary = [ordered]@{
        Project              = "Project Hermes"
        ScriptVersion        = $Context.ScriptVersion
        BaselineTimestamp    = $Context.RunTimestamp
        ComputerName         = $env:COMPUTERNAME
        UserName             = $env:USERNAME
        WindowsEdition       = $operatingSystem.Caption
        WindowsVersion       = $operatingSystem.Version
        PowerShellVersion    = $PSVersionTable.PSVersion.ToString()
        IsAdministrator      = $Context.IsAdministrator
        ProjectRoot          = $Context.ProjectRoot
        BaselineOutputFolder = $Context.BaselineRoot
        Results              = @($Context.Results)
    }

    $summaryPath = Join-Path $Context.BaselineRoot "baseline-summary.json"
    $baselineSummary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    Add-HermesResult -Context $Context -Step "Baseline summary" -Status "Succeeded" -Message "Baseline summary created." -OutputPath $summaryPath
}

function Complete-HermesRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Context,

        [switch]$Succeeded,

        $ErrorRecord
    )

    $Context.CompletedAt = Get-Date
    [System.IO.Directory]::CreateDirectory($Context.SummaryDirectory) | Out-Null

    $counts = @{
        Succeeded = @($Context.Results | Where-Object Status -eq "Succeeded").Count
        Warning   = @($Context.Results | Where-Object Status -eq "Warning").Count
        Skipped   = @($Context.Results | Where-Object Status -eq "Skipped").Count
        Failed    = @($Context.Results | Where-Object Status -eq "Failed").Count
    }

    $summary = [ordered]@{
        Project         = "Project Hermes"
        RunId           = $Context.RunId
        ScriptVersion   = $Context.ScriptVersion
        ProjectRoot     = $Context.ProjectRoot
        StartedAt       = $Context.StartedAt.ToString("o")
        CompletedAt     = $Context.CompletedAt.ToString("o")
        DurationSeconds = [math]::Round(($Context.CompletedAt - $Context.StartedAt).TotalSeconds, 2)
        Succeeded       = [bool]$Succeeded
        IsAdministrator = $Context.IsAdministrator
        Counts          = $counts
        Error           = if ($ErrorRecord) { $ErrorRecord.Exception.Message } else { $null }
        Results         = @($Context.Results)
    }

    $summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Context.SummaryFile -Encoding UTF8
    Save-HermesState -Context $Context

    if ($Succeeded) {
        Write-HermesLog -Context $Context -Message "Project Hermes initialization completed successfully." -Level "SUCCESS"
    }
    else {
        Write-HermesLog -Context $Context -Message "Project Hermes initialization failed: $($ErrorRecord.Exception.Message)" -Level "ERROR"
    }

    Write-Host ""
    Write-Host "Project root:   $($Context.ProjectRoot)"
    Write-Host "Log file:       $($Context.LogFile)"
    Write-Host "Summary file:   $($Context.SummaryFile)"
    Write-Host "Succeeded:      $($counts.Succeeded)"
    Write-Host "Warnings:       $($counts.Warning)"
    Write-Host "Skipped:        $($counts.Skipped)"
    Write-Host "Failed:         $($counts.Failed)"
}

Export-ModuleMember -Function @(
    "New-HermesContext",
    "Start-HermesRun",
    "Initialize-HermesRepository",
    "Invoke-HermesBaseline",
    "Add-HermesResult",
    "Complete-HermesRun"
)
