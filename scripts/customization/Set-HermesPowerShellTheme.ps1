[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$terminalSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$profilePath = $PROFILE.CurrentUserAllHosts
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $PSScriptRoot 'exports\backups\hermes.theme'
[IO.Directory]::CreateDirectory($backupRoot) | Out-Null

$scheme = [ordered]@{
    name                = 'Project Hermes Gothic'
    background          = '#07050D'
    foreground          = '#E8E2F2'
    cursorColor         = '#C45CFF'
    selectionBackground = '#4A2466'
    black               = '#09070F'
    red                 = '#FF5577'
    green               = '#48E59B'
    yellow              = '#E8B95B'
    blue                = '#7289FF'
    purple              = '#C45CFF'
    cyan                = '#55DDF0'
    white               = '#E8E2F2'
    brightBlack         = '#625A70'
    brightRed           = '#FF7892'
    brightGreen         = '#71F0B5'
    brightYellow        = '#FFD27A'
    brightBlue          = '#91A2FF'
    brightPurple        = '#DB8CFF'
    brightCyan          = '#82EAF6'
    brightWhite         = '#FFFFFF'
}

if (-not (Test-Path -LiteralPath $terminalSettings -PathType Leaf)) {
    throw "Windows Terminal settings were not found at '$terminalSettings'."
}

if ($PSCmdlet.ShouldProcess($terminalSettings, 'Apply Project Hermes Gothic terminal theme')) {
    $terminalBackup = Join-Path $backupRoot "windows-terminal-settings.$stamp.json"
    [IO.File]::Copy($terminalSettings, $terminalBackup, $true)
    $settings = Get-Content -LiteralPath $terminalSettings -Raw | ConvertFrom-Json -AsHashtable

    if (-not $settings.Contains('schemes')) { $settings.schemes = @() }
    $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne $scheme.name }) + @($scheme)

    if (-not $settings.Contains('profiles')) { $settings.profiles = @{} }
    if (-not $settings.profiles.Contains('defaults')) { $settings.profiles.defaults = @{} }
    $defaults = $settings.profiles.defaults
    $defaults.colorScheme = $scheme.name
    $defaults.font = @{ face = 'Cascadia Mono'; size = 11 }
    $defaults.opacity = 94
    $defaults.useAcrylic = $true
    $defaults.acrylicOpacity = 0.82
    $defaults.cursorShape = 'bar'
    $defaults.cursorColor = '#C45CFF'
    $defaults.padding = '12, 10, 12, 10'

    $settings.theme = 'dark'
    $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $terminalSettings -Encoding utf8NoBOM
}

$startMarker = '# >>> Project Hermes Gothic PowerShell >>>'
$endMarker = '# <<< Project Hermes Gothic PowerShell <<<'
$managedBlock = @"
$startMarker
`$PSStyle.Formatting.Error = "`e[38;2;255;85;119m"
`$PSStyle.Formatting.Warning = "`e[38;2;232;185;91m"
`$PSStyle.Formatting.Verbose = "`e[38;2;114;137;255m"
`$PSStyle.Formatting.Debug = "`e[38;2;196;92;255m"
`$PSStyle.Formatting.TableHeader = "`e[38;2;196;92;255m"

function global:prompt {
    `$identity = "`e[38;2;196;92;255mPS"
    `$location = "`e[38;2;85;221;240m`$(`$executionContext.SessionState.Path.CurrentLocation)"
    `$reset = "`e[0m"
    "`$identity `$location`$reset`n❯ "
}
$endMarker
"@

if ($PSCmdlet.ShouldProcess($profilePath, 'Install Project Hermes Gothic PowerShell colors')) {
    $profileDirectory = Split-Path -Parent $profilePath
    [IO.Directory]::CreateDirectory($profileDirectory) | Out-Null
    $existing = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
    if (Test-Path -LiteralPath $profilePath) {
        $profileBackup = Join-Path $backupRoot "powershell-profile.$stamp.ps1"
        [IO.File]::Copy($profilePath, $profileBackup, $true)
    }
    $pattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
    $existing = [regex]::Replace($existing, $pattern, '').TrimEnd()
    $combined = if ([string]::IsNullOrWhiteSpace($existing)) { $managedBlock } else { "$existing`r`n`r`n$managedBlock" }
    Set-Content -LiteralPath $profilePath -Value $combined -Encoding utf8NoBOM
}

Write-Host 'Project Hermes Gothic Terminal and PowerShell theme installed.' -ForegroundColor Magenta
Write-Host 'Close and reopen Windows Terminal to see the complete result.' -ForegroundColor Cyan
