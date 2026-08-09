[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

function Start-HermesTarget {
    param(
        [Parameter(Mandatory)][string[]]$Candidates,
        [string[]]$ArgumentList = @(),
        [string]$FallbackUri
    )

    foreach ($candidate in $Candidates) {
        $expanded = [Environment]::ExpandEnvironmentVariables($candidate)
        $command = Get-Command $expanded -ErrorAction SilentlyContinue
        $target = if ($command) { $command.Source } elseif (Test-Path -LiteralPath $expanded) { $expanded } else { $null }

        if ($target) {
            Start-Process -FilePath $target -ArgumentList $ArgumentList
            return
        }
    }

    if ($FallbackUri) {
        Start-Process $FallbackUri
        return
    }

    throw "No installed application was found for '$Action'."
}

function Start-HermesInstalledApp {
    param(
        [Parameter(Mandatory)][string[]]$DisplayNames,
        [Parameter(Mandatory)][string[]]$Candidates,
        [Parameter(Mandatory)][string]$DownloadUri,
        [string[]]$ArgumentList = @()
    )

    $startApps = @(Get-StartApps -ErrorAction SilentlyContinue)
    foreach ($displayName in $DisplayNames) {
        $app = $startApps |
            Where-Object { $_.Name -like "*$displayName*" } |
            Select-Object -First 1

        if ($app -and $app.AppID) {
            Start-Process -FilePath 'explorer.exe' -ArgumentList "shell:AppsFolder\$($app.AppID)"
            return
        }
    }

    Start-HermesTarget -Candidates $Candidates -ArgumentList $ArgumentList -FallbackUri $DownloadUri
}

function Start-HermesUri {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [string]$FallbackUri,

        [string]$DisplayName = 'application'
    )

    try {
        Start-Process $Uri -ErrorAction Stop
    }
    catch {
        if ($FallbackUri) {
            Start-Process $FallbackUri
            return
        }

        throw "$DisplayName is not installed and no fallback is configured."
    }
}

function Get-HermesSetting {
    param([Parameter(Mandatory)][string]$Name)

    $settingsPath = Join-Path $PSScriptRoot 'HermesLauncher.settings.psd1'
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        $settingsPath = Join-Path $PSScriptRoot 'HermesLauncher.settings.example.psd1'
    }
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) { return '' }
    $settings = Import-PowerShellDataFile -LiteralPath $settingsPath
    if ($settings.ContainsKey($Name)) { return [string]$settings[$Name] }
    return ''
}

function Start-HermesConfiguredUri {
    param([Parameter(Mandatory)][string]$Name)
    $uri = Get-HermesSetting -Name $Name
    if ([string]::IsNullOrWhiteSpace($uri)) {
        throw "Configure '$Name' in '$PSScriptRoot\HermesLauncher.settings.psd1' before using this launcher."
    }
    Start-HermesUri -Uri $uri
}

$projectsRoot = Join-Path $HOME 'Projects'
$hermesRoot = Join-Path $projectsRoot 'Project-Hermes'

try {
    switch ($Action.ToLowerInvariant()) {
        'discord'       { Start-HermesInstalledApp @('Discord') @('Discord.exe', '%LOCALAPPDATA%\Discord\Update.exe') 'https://discord.com/download' }
        'slack'         { Start-HermesInstalledApp @('Slack') @('slack.exe', '%LOCALAPPDATA%\slack\slack.exe') 'https://slack.com/downloads/windows' }
        'teams'         { Start-HermesInstalledApp @('Microsoft Teams', 'Teams') @('ms-teams.exe', 'Teams.exe') 'https://www.microsoft.com/microsoft-teams/download-app' }
        'telegram'      { Start-HermesInstalledApp @('Telegram Desktop', 'Telegram') @('Telegram.exe', '%APPDATA%\Telegram Desktop\Telegram.exe') 'https://desktop.telegram.org/' }
        'signal'        { Start-HermesInstalledApp @('Signal') @('Signal.exe', '%LOCALAPPDATA%\Programs\signal-desktop\Signal.exe') 'https://signal.org/download/' }
        'mail'          { Start-HermesInstalledApp @('Mozilla Thunderbird', 'Thunderbird') @('thunderbird.exe', '%ProgramFiles%\Mozilla Thunderbird\thunderbird.exe') 'https://www.thunderbird.net/download/' }
        'outlook'       { Start-HermesInstalledApp @('Outlook') @('olk.exe', 'outlook.exe') 'https://www.microsoft.com/microsoft-365/outlook/outlook-for-windows' }
        'matrix'        { Start-HermesInstalledApp @('Element') @('Element.exe', '%LOCALAPPDATA%\element-desktop\Element.exe') 'https://element.io/download' }
        'libreoffice'   { Start-HermesInstalledApp @('LibreOffice') @('soffice.exe', '%ProgramFiles%\LibreOffice\program\soffice.exe') 'https://www.libreoffice.org/download/download-libreoffice/' }
        'notepad++'     { Start-HermesInstalledApp @('Notepad++') @('notepad++.exe', '%ProgramFiles%\Notepad++\notepad++.exe') 'https://notepad-plus-plus.org/downloads/' }
        'obsidian'      { Start-HermesInstalledApp @('Obsidian') @('Obsidian.exe', '%LOCALAPPDATA%\Obsidian\Obsidian.exe') 'https://obsidian.md/download' }
        'vscode'        { Start-HermesInstalledApp @('Visual Studio Code') @('code.cmd', 'code.exe') 'https://code.visualstudio.com/download' }
        'files'         { Start-HermesTarget @('explorer.exe') @($HOME) }
        'browser'       { Start-HermesUri (Get-HermesSetting -Name 'BrowserUrl') }
        'onedrive'      { Start-HermesTarget @('explorer.exe') @((Join-Path $HOME 'OneDrive')) }
        'notes'         { Start-HermesTarget @('notepad++.exe', 'notepad.exe') }
        'wireshark'     { Start-HermesInstalledApp @('Wireshark') @('wireshark.exe', '%ProgramFiles%\Wireshark\Wireshark.exe') 'https://www.wireshark.org/download.html' }
        'nmap'          { Start-HermesInstalledApp @('Zenmap', 'Nmap') @('zenmap.exe', 'nmap.exe') 'https://nmap.org/download.html' }
        'netwatch'      { Start-HermesConfiguredUri 'NetWatchUrl' }
        'wazuh'         { Start-HermesConfiguredUri 'WazuhUrl' }
        'ssh'           { Start-HermesTarget @('wt.exe') @('ssh', (Get-HermesSetting -Name 'SshHost')) }
        'remote'        { Start-HermesTarget @('code.cmd', 'code.exe') @('--remote', "ssh-remote+$(Get-HermesSetting -Name 'SshHost')", (Get-HermesSetting -Name 'RemotePath')) }
        'vpn'           { Start-HermesUri 'ms-settings:network-vpn' }
        'caddy'         { Start-HermesConfiguredUri 'CaddyUrl' }
        'github'        { Start-HermesUri 'https://github.com/scott-renny/project-hermes' }
        'drawio'        { Start-HermesUri 'https://app.diagrams.net/' }
        'project'       { Start-HermesTarget @('explorer.exe') @($hermesRoot) }
        'docs'          { Start-HermesTarget @('explorer.exe') @((Join-Path $hermesRoot 'docs')) }
        'architecture'  { Start-HermesTarget @('code.cmd', 'code.exe') @('--remote', "ssh-remote+$(Get-HermesSetting -Name 'SshHost')", "$(Get-HermesSetting -Name 'RemotePath')/docs") }
        'runbooks'      { Start-HermesUri 'https://github.com/scott-renny/cyber-operations-center-engineering-program/search?q=RB-&type=code' }
        'policies'      { Start-HermesUri 'https://github.com/scott-renny/cyber-operations-center-engineering-program/search?q=policy&type=code' }
        'repository'    { Start-HermesUri 'https://github.com/scott-renny/cyber-operations-center-engineering-program' }
        'terminal'      { Start-HermesTarget @('wt.exe') }
        'powershell'    { Start-HermesTarget @('pwsh.exe', 'powershell.exe') }
        'bitwarden'     { Start-HermesInstalledApp @('Bitwarden') @('Bitwarden.exe', '%LOCALAPPDATA%\Programs\Bitwarden\Bitwarden.exe') 'https://bitwarden.com/download/' }
        '7zip'          { Start-HermesInstalledApp @('7-Zip') @('7zFM.exe', '%ProgramFiles%\7-Zip\7zFM.exe') 'https://www.7-zip.org/download.html' }
        'everything'    { Start-HermesInstalledApp @('Everything') @('Everything.exe', '%ProgramFiles%\Everything\Everything.exe') 'https://www.voidtools.com/downloads/' }
        'settings'      { Start-HermesUri 'ms-settings:' }
        'taskmanager'   { Start-HermesTarget @('taskmgr.exe') }
        'recycle'       { Start-HermesTarget @('explorer.exe') @('shell:RecycleBinFolder') }
        default         { throw "Unknown Hermes launcher action '$Action'." }
    }
}
catch {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        $_.Exception.Message,
        'Project Hermes Launcher',
        'OK',
        'Warning'
    ) | Out-Null
    exit 1
}
