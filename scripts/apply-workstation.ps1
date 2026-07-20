[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProfilePath = (
        Join-Path `
            $PSScriptRoot `
            "..\config\profiles\engineering-workstation.json"
    ),

    [Parameter()]
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (
    Join-Path $PSScriptRoot ".."
)

$configurationModule = Join-Path `
    $repositoryRoot `
    "modules\utilities\Hermes.Configuration.psm1"

try {
    Import-Module `
        $configurationModule `
        -Force `
        -ErrorAction Stop

    $resolvedProfilePath = Resolve-Path `
        -LiteralPath $ProfilePath `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "Loading Project Hermes workstation profile..."

    $configuration = Import-HermesConfiguration `
        -Path $resolvedProfilePath

    $validation = Test-HermesConfiguration `
        -Configuration $configuration

    if (-not $validation.IsValid) {
        Write-Host ""
        Write-Host "Configuration validation failed."

        foreach ($validationError in $validation.Errors) {
            Write-Host "  - $validationError"
        }

        exit 1
    }

    Write-Host "Configuration validation passed."

    Show-HermesConfigurationSummary `
        -Configuration $configuration

    if ($ValidateOnly) {
        Write-Host "Validation-only mode completed successfully."
        exit 0
    }

    Write-Host "No workstation changes were applied."
    Write-Host "Configuration modules will be added during v0.5.0."
}
catch {
    Write-Error "Project Hermes failed: $($_.Exception.Message)"
    exit 1
}