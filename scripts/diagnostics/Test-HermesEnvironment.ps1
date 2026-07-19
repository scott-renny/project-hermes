[CmdletBinding()]
param(
    [switch]$Detailed,
    [switch]$FailOnWarning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$CoreModulePath = Join-Path $RepositoryRoot 'scripts\modules\Hermes.Core.psm1'

if (-not (Test-Path -LiteralPath $CoreModulePath)) {
    throw "Hermes core module was not found at: $CoreModulePath"
}

Import-Module $CoreModulePath -Force

$Results = [System.Collections.Generic.List[object]]::new()

function Add-HermesValidationResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Passed', 'Warning', 'Failed')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Value
    )

    $Results.Add([pscustomobject]@{
        Name    = $Name
        Status  = $Status
        Message = $Message
        Value   = $Value
    })
}

function Test-HermesCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string]$DisplayName,

        [scriptblock]$VersionCommand
    )

    $Command = Get-Command $CommandName -ErrorAction SilentlyContinue

    if (-not $Command) {
        Add-HermesValidationResult `
            -Name $DisplayName `
            -Status 'Failed' `
            -Message "$DisplayName was not found in the current PATH."

        return
    }

    $Version = $null

    if ($VersionCommand) {
        try {
            $Version = & $VersionCommand
        }
        catch {
            $Version = 'Installed; version could not be determined'
        }
    }

    Add-HermesValidationResult `
        -Name $DisplayName `
        -Status 'Passed' `
        -Message "$DisplayName is available." `
        -Value $Version
}

Write-Host ''
Write-Host 'Project Hermes Environment Validation' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host ''

if (Test-Path -LiteralPath $RepositoryRoot) {
    Add-HermesValidationResult `
        -Name 'Repository root' `
        -Status 'Passed' `
        -Message 'The Project Hermes repository root was located.' `
        -Value $RepositoryRoot
}
else {
    Add-HermesValidationResult `
        -Name 'Repository root' `
        -Status 'Failed' `
        -Message 'The Project Hermes repository root could not be located.'
}

$RequiredPaths = @(
    'configs',
    'scripts',
    'scripts\bootstrap',
    'scripts\modules'
)

foreach ($RelativePath in $RequiredPaths) {
    $FullPath = Join-Path $RepositoryRoot $RelativePath

    if (Test-Path -LiteralPath $FullPath) {
        Add-HermesValidationResult `
            -Name "Path: $RelativePath" `
            -Status 'Passed' `
            -Message 'Required repository path exists.' `
            -Value $FullPath
    }
    else {
        Add-HermesValidationResult `
            -Name "Path: $RelativePath" `
            -Status 'Failed' `
            -Message 'Required repository path is missing.' `
            -Value $FullPath
    }
}

Test-HermesCommand `
    -CommandName 'git' `
    -DisplayName 'Git' `
    -VersionCommand { (git --version) -join ' ' }

Test-HermesCommand `
    -CommandName 'gh' `
    -DisplayName 'GitHub CLI' `
    -VersionCommand { (gh --version | Select-Object -First 1) }

Test-HermesCommand `
    -CommandName 'code' `
    -DisplayName 'Visual Studio Code' `
    -VersionCommand { (code --version | Select-Object -First 1) }

Test-HermesCommand `
    -CommandName 'pwsh' `
    -DisplayName 'PowerShell 7' `
    -VersionCommand { (pwsh --version) -join ' ' }

$WingetCommand = Get-Command winget -ErrorAction SilentlyContinue

if ($WingetCommand) {
    Add-HermesValidationResult `
        -Name 'WinGet' `
        -Status 'Passed' `
        -Message 'WinGet is available.' `
        -Value ((winget --version) -join ' ')
}
else {
    Add-HermesValidationResult `
        -Name 'WinGet' `
        -Status 'Warning' `
        -Message 'WinGet was not found. Package deployment will not be available.'
}

$GitRepositoryCheck = git -C $RepositoryRoot rev-parse --is-inside-work-tree 2>$null

if ($LASTEXITCODE -eq 0 -and $GitRepositoryCheck -eq 'true') {
    Add-HermesValidationResult `
        -Name 'Git repository' `
        -Status 'Passed' `
        -Message 'The Project Hermes folder is a valid Git working tree.'
}
else {
    Add-HermesValidationResult `
        -Name 'Git repository' `
        -Status 'Failed' `
        -Message 'The Project Hermes folder is not a valid Git working tree.'
}

$GitRemote = git -C $RepositoryRoot remote get-url origin 2>$null

if ($LASTEXITCODE -eq 0 -and $GitRemote) {
    Add-HermesValidationResult `
        -Name 'Git origin remote' `
        -Status 'Passed' `
        -Message 'The origin remote is configured.' `
        -Value $GitRemote
}
else {
    Add-HermesValidationResult `
        -Name 'Git origin remote' `
        -Status 'Warning' `
        -Message 'The origin remote is not configured.'
}

$StatusSymbols = @{
    Passed  = '[PASS]'
    Warning = '[WARN]'
    Failed  = '[FAIL]'
}

foreach ($Result in $Results) {
    $Color = switch ($Result.Status) {
        'Passed'  { 'Green' }
        'Warning' { 'Yellow' }
        'Failed'  { 'Red' }
    }

    Write-Host "$($StatusSymbols[$Result.Status]) $($Result.Name): $($Result.Message)" -ForegroundColor $Color

    if ($Detailed -and $Result.Value) {
        Write-Host "       $($Result.Value)" -ForegroundColor DarkGray
    }
}

$PassedCount = @($Results | Where-Object Status -eq 'Passed').Count
$WarningCount = @($Results | Where-Object Status -eq 'Warning').Count
$FailedCount = @($Results | Where-Object Status -eq 'Failed').Count

Write-Host ''
Write-Host 'Validation summary' -ForegroundColor Cyan
Write-Host "Passed:   $PassedCount"
Write-Host "Warnings: $WarningCount"
Write-Host "Failed:   $FailedCount"
Write-Host ''

if ($FailedCount -gt 0) {
    exit 1
}

if ($FailOnWarning -and $WarningCount -gt 0) {
    exit 2
}

exit 0
