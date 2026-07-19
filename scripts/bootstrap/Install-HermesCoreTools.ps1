<#
.SYNOPSIS
    Plans or installs the Project Hermes core development toolset.

.DESCRIPTION
    Without -Apply, this script performs a safe deployment preview.
    With -Apply, it installs required packages from the reviewed JSON manifest.

.EXAMPLE
    .\Install-HermesCoreTools.ps1

.EXAMPLE
    .\Install-HermesCoreTools.ps1 -Apply

.EXAMPLE
    .\Install-HermesCoreTools.ps1 -Apply -IncludeOptional
#>

[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$IncludeOptional,
    [switch]$ForceReinstall,
    [ValidateRange(60, 3600)]
    [int]$PackageTimeoutSeconds = 1200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path $projectRoot "scripts\modules\Hermes.Install.psm1"
$manifestPath = Join-Path $projectRoot "configs\packages\core-development.json"

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Required installer module not found: $modulePath"
}

Import-Module $modulePath -Force

Install-HermesCoreTools `
    -ProjectRoot $projectRoot `
    -ManifestPath $manifestPath `
    -Apply:$Apply `
    -IncludeOptional:$IncludeOptional `
    -ForceReinstall:$ForceReinstall `
    -PackageTimeoutSeconds $PackageTimeoutSeconds
