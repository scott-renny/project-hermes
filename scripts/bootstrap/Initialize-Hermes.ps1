<#
.SYNOPSIS
    Initializes the Project Hermes workstation foundation.

.DESCRIPTION
    Creates the Project Hermes repository structure, collects a Windows
    workstation baseline, records structured progress, and writes a final
    execution summary.

    Version 0.2.0 is non-destructive. It does not install or remove software
    and does not modify Windows settings.

.NOTES
    Project: Project Hermes
    Script: Initialize-Hermes.ps1
    Version: 0.2.0
    Author: Scott Renny
    Requires: Windows PowerShell 5.1 or PowerShell 7+
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),

    [Parameter()]
    [switch]$SkipBaseline,

    [Parameter()]
    [switch]$SkipWinget,

    [Parameter()]
    [ValidateRange(10, 600)]
    [int]$WingetTimeoutSeconds = 90,

    [Parameter()]
    [switch]$Resume,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\Hermes.Core.psm1"

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Required module not found: $modulePath"
}

Import-Module $modulePath -Force

$context = New-HermesContext `
    -ProjectRoot $ProjectRoot `
    -ScriptVersion "0.2.0" `
    -WingetTimeoutSeconds $WingetTimeoutSeconds `
    -SkipWinget:$SkipWinget `
    -Resume:$Resume `
    -Force:$Force

try {
    Start-HermesRun -Context $context
    Initialize-HermesRepository -Context $context

    if (-not $SkipBaseline) {
        Invoke-HermesBaseline -Context $context
    }
    else {
        Add-HermesResult -Context $context -Step "Baseline" -Status "Skipped" -Message "Baseline collection skipped by request."
    }

    Complete-HermesRun -Context $context -Succeeded
}
catch {
    Add-HermesResult -Context $context -Step "Initialization" -Status "Failed" -Message $_.Exception.Message
    Complete-HermesRun -Context $context -ErrorRecord $_
    exit 1
}
