Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Get-HermesWinget {
    $command = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidate = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe"
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }

    return $null
}

function Invoke-HermesProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList,
        [Parameter(Mandatory)][string]$StandardOutputPath,
        [Parameter(Mandatory)][string]$StandardErrorPath,
        [ValidateRange(30, 3600)][int]$TimeoutSeconds = 900
    )

    $process = Start-Process `
        -FilePath $FilePath `
        -ArgumentList $ArgumentList `
        -RedirectStandardOutput $StandardOutputPath `
        -RedirectStandardError $StandardErrorPath `
        -PassThru `
        -WindowStyle Hidden

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $process.Kill()
            $process.WaitForExit()
        }
        catch {}

        return [pscustomobject]@{
            ExitCode = $null
            TimedOut = $true
        }
    }

    # Windows PowerShell may not populate ExitCode until the process object is refreshed.
    $process.Refresh()
    $capturedExitCode = $process.ExitCode

    return [pscustomobject]@{
        ExitCode = [int]$capturedExitCode
        TimedOut = $false
    }
}

function Test-HermesPackageInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WingetPath,
        [Parameter(Mandatory)][string]$PackageId,
        [Parameter(Mandatory)][string]$WorkingDirectory
    )

    $safeName = $PackageId -replace '[^a-zA-Z0-9.-]', '_'
    $stdout = Join-Path $WorkingDirectory "$safeName-list.out.txt"
    $stderr = Join-Path $WorkingDirectory "$safeName-list.err.txt"

    $result = Invoke-HermesProcess `
        -FilePath $WingetPath `
        -ArgumentList @(
            "list",
            "--id", $PackageId,
            "--exact",
            "--source", "winget",
            "--accept-source-agreements",
            "--disable-interactivity"
        ) `
        -StandardOutputPath $stdout `
        -StandardErrorPath $stderr `
        -TimeoutSeconds 120

    if ($result.TimedOut) { return $false }

    $content = if (Test-Path -LiteralPath $stdout) {
        Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
    } else { "" }

    return ($result.ExitCode -eq 0 -and $content -match [regex]::Escape($PackageId))
}

function Install-HermesPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WingetPath,
        [Parameter(Mandatory)]$Package,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [ValidateRange(60, 3600)][int]$TimeoutSeconds = 1200
    )

    $safeName = $Package.id -replace '[^a-zA-Z0-9.-]', '_'
    $stdout = Join-Path $WorkingDirectory "$safeName-install.out.txt"
    $stderr = Join-Path $WorkingDirectory "$safeName-install.err.txt"

    $arguments = @(
        "install",
        "--id", [string]$Package.id,
        "--exact",
        "--source", "winget",
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--disable-interactivity",
        "--silent"
    )

    $result = Invoke-HermesProcess `
        -FilePath $WingetPath `
        -ArgumentList $arguments `
        -StandardOutputPath $stdout `
        -StandardErrorPath $stderr `
        -TimeoutSeconds $TimeoutSeconds

    [pscustomobject]@{
        PackageId = [string]$Package.id
        Name      = [string]$Package.name
        Required  = [bool]$Package.required
        ExitCode  = $result.ExitCode
        TimedOut  = $result.TimedOut
        StdOut    = $stdout
        StdErr    = $stderr
    }
}

function Update-HermesProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = @($machinePath, $userPath) -join ";"
}

function Install-HermesCoreTools {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ManifestPath,
        [switch]$Apply,
        [switch]$IncludeOptional,
        [switch]$ForceReinstall,
        [ValidateRange(60, 3600)][int]$PackageTimeoutSeconds = 1200
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Package manifest not found: $ManifestPath"
    }

    $winget = Get-HermesWinget
    if (-not $winget) {
        throw "WinGet is unavailable. Open Microsoft Store, update App Installer, then reopen PowerShell."
    }

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $runDirectory = Join-Path $ProjectRoot "logs\install-$timestamp"
    [System.IO.Directory]::CreateDirectory($runDirectory) | Out-Null

    $selectedPackages = @($manifest.packages | Where-Object {
        $_.required -eq $true -or $IncludeOptional
    })

    Write-Host ""
    Write-Host "Project Hermes Core Tool Deployment"
    Write-Host "Manifest:       $ManifestPath"
    Write-Host "Administrator:  $(Test-HermesAdministrator)"
    Write-Host "Apply changes:  $Apply"
    Write-Host ""

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($package in $selectedPackages) {
        $installed = Test-HermesPackageInstalled `
            -WingetPath $winget `
            -PackageId $package.id `
            -WorkingDirectory $runDirectory

        if ($installed -and -not $ForceReinstall) {
            Write-Host "[SKIPPED] $($package.name) is already installed." -ForegroundColor Yellow
            $results.Add([pscustomobject]@{
                PackageId = $package.id
                Name = $package.name
                Status = "Skipped"
                Message = "Already installed"
                ExitCode = 0
            })
            continue
        }

        if (-not $Apply) {
            Write-Host "[PLAN] Would install $($package.name) [$($package.id)]"
            $results.Add([pscustomobject]@{
                PackageId = $package.id
                Name = $package.name
                Status = "Planned"
                Message = "Run again with -Apply to install"
                ExitCode = $null
            })
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($package.id, "Install package with WinGet")) {
            continue
        }

        Write-Host "[INSTALLING] $($package.name) [$($package.id)]"

        $installResult = Install-HermesPackage `
            -WingetPath $winget `
            -Package $package `
            -WorkingDirectory $runDirectory `
            -TimeoutSeconds $PackageTimeoutSeconds

        if ($installResult.TimedOut) {
            $status = if ($package.required) { "Failed" } else { "Warning" }
            Write-Host "[$status] $($package.name) timed out." -ForegroundColor Red
            $message = "Installation timed out"
        }
        elseif ($installResult.ExitCode -eq 0) {
            $status = "Succeeded"
            Write-Host "[SUCCESS] $($package.name) installed." -ForegroundColor Green
            $message = "Installed successfully"
        }
        else {
            $status = if ($package.required) { "Failed" } else { "Warning" }
            Write-Host "[$status] $($package.name) exited with code $($installResult.ExitCode)." -ForegroundColor Red
            $message = "Installer exited with code $($installResult.ExitCode)"
        }

        $results.Add([pscustomobject]@{
            PackageId = $package.id
            Name = $package.name
            Status = $status
            Message = $message
            ExitCode = $installResult.ExitCode
            StdOut = $installResult.StdOut
            StdErr = $installResult.StdErr
        })
    }

    Update-HermesProcessPath

    $summaryPath = Join-Path $runDirectory "installation-summary.json"
    [ordered]@{
        Project = "Project Hermes"
        Version = "0.3.1"
        Profile = $manifest.profile
        Timestamp = (Get-Date).ToString("o")
        Applied = [bool]$Apply
        IncludeOptional = [bool]$IncludeOptional
        Results = @($results)
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

    Write-Host ""
    Write-Host "Summary: $summaryPath"

    $requiredFailures = @($results | Where-Object { $_.Status -eq "Failed" })
    if ($requiredFailures.Count -gt 0) {
        throw "$($requiredFailures.Count) required package installation(s) failed. Review the summary and package logs."
    }

    return @($results)
}

Export-ModuleMember -Function @(
    "Install-HermesCoreTools",
    "Update-HermesProcessPath"
)
