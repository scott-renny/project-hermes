[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$RestartExplorer
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $PSScriptRoot 'exports\backups\hermes.explorer-theme'
[IO.Directory]::CreateDirectory($backupRoot) | Out-Null

$keys = [ordered]@{
    Personalize = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Advanced    = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Accent      = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
    Dwm         = 'HKCU\Software\Microsoft\Windows\DWM'
    Desktop     = 'HKCU\Control Panel\Desktop'
}

foreach ($entry in $keys.GetEnumerator()) {
    $destination = Join-Path $backupRoot "$($entry.Key)-$stamp.reg"
    & reg.exe export $entry.Value $destination /y 2>$null | Out-Null
}

function Set-HermesRegistryDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][uint32]$Value
    )

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set DWORD value to $Value")) {
        & reg.exe add $Path /v $Name /t REG_DWORD /d $Value /f | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to set '$Path\$Name'." }
    }
}

# Stable Windows dark-mode and transparency preferences.
Set-HermesRegistryDword $keys.Personalize AppsUseLightTheme 0
Set-HermesRegistryDword $keys.Personalize SystemUsesLightTheme 0
Set-HermesRegistryDword $keys.Personalize EnableTransparency 1
Set-HermesRegistryDword $keys.Personalize ColorPrevalence 1
Set-HermesRegistryDword $keys.Personalize ColorPrevalance 1
Set-HermesRegistryDword $keys.Desktop AutoColorization 0

# Compact, engineering-oriented File Explorer preferences.
Set-HermesRegistryDword $keys.Advanced UseCompactMode 1
Set-HermesRegistryDword $keys.Advanced HideFileExt 0
Set-HermesRegistryDword $keys.Advanced ShowStatusBar 1
Set-HermesRegistryDword $keys.Advanced SeparateProcess 0

# Project Hermes violet accent: #C45CFF represented in Windows ABGR form.
Set-HermesRegistryDword $keys.Dwm ColorPrevalence 1
Set-HermesRegistryDword $keys.Dwm AccentColor 4294925508
Set-HermesRegistryDword $keys.Dwm AccentColorInactive 4287589557

# Windows shell palette, from lightest through darkest violet. Windows uses
# this palette for selection, Settings links, shell controls, and hover states.
$accentPalette = 'f0dfff00e0bfff00d18fff00c45cff00a83edf007d2ba800531d70002b103d00'
if ($PSCmdlet.ShouldProcess($keys.Accent, 'Install Project Hermes violet shell palette')) {
    & reg.exe add $keys.Accent /v AccentColorMenu /t REG_DWORD /d 0xFFFF5CC4 /f | Out-Null
    & reg.exe add $keys.Accent /v StartColorMenu /t REG_DWORD /d 0xFF3D102B /f | Out-Null
    & reg.exe add $keys.Accent /v AccentPalette /t REG_BINARY /d $accentPalette /f | Out-Null
    & reg.exe add $keys.Dwm /v ColorizationColor /t REG_DWORD /d 0xFFC45CFF /f | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Failed to install the Project Hermes accent palette.' }
}

if ($RestartExplorer -and $PSCmdlet.ShouldProcess('Windows Explorer', 'Restart to apply visual settings')) {
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

Write-Host 'Project Hermes Explorer preferences installed.' -ForegroundColor Magenta
Write-Host 'Sign out and back in for every Windows accent surface to refresh.' -ForegroundColor Cyan
Write-Host "Backups: $backupRoot" -ForegroundColor DarkGray
