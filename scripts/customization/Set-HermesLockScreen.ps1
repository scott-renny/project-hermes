[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$ImagePath,
    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $ImagePath) {
    $ImagePath = Join-Path $repositoryRoot 'assets\lockscreens\hermes-gothic-lockscreen-v2.png'
}
$ImagePath = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($ImagePath))
if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) { throw "Lock-screen image was not found at '$ImagePath'." }

$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
$backupPath = Join-Path $repositoryRoot ('exports\backups\lockscreen\Hermes-LockScreen-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$names = @('LockScreenImagePath', 'LockScreenImageUrl', 'LockScreenImageStatus')

if (-not $PSCmdlet.ShouldProcess($ImagePath, 'Apply Project Hermes lock screen')) { return }

if (-not $SkipBackup) {
    $backup = [ordered]@{ CapturedAt = (Get-Date).ToString('o'); RegistryPath = $registryPath; Values = [ordered]@{} }
    foreach ($name in $names) {
        $value = Get-ItemPropertyValue -Path $registryPath -Name $name -ErrorAction SilentlyContinue
        $backup.Values[$name] = @{ Exists = ($null -ne $value); Value = $value }
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
    $backup | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $backupPath -Encoding utf8NoBOM
}

try {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name LockScreenImagePath -Value $ImagePath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name LockScreenImageUrl -Value $ImagePath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name LockScreenImageStatus -Value 1 -PropertyType DWord -Force | Out-Null
}
catch [System.UnauthorizedAccessException] {
    throw 'Applying the lock screen requires an elevated PowerShell window. Right-click PowerShell, choose Run as administrator, and run this script again.'
}

[pscustomobject]@{
    Changed    = $true
    ImagePath  = $ImagePath
    BackupPath = if ($SkipBackup) { $null } else { $backupPath }
    SignOutMayBeRequired = $true
}
