Set-StrictMode -Version Latest

function Import-HermesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Hermes configuration file was not found: $Path"
    }

    try {
        $rawConfiguration = Get-Content `
            -LiteralPath $Path `
            -Raw `
            -ErrorAction Stop

        $configuration = $rawConfiguration |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Unable to load Hermes configuration '$Path'. $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace($configuration.schemaVersion)) {
        throw "Configuration is missing the required 'schemaVersion' property."
    }

    if ([string]::IsNullOrWhiteSpace($configuration.profileName)) {
        throw "Configuration is missing the required 'profileName' property."
    }

    return $configuration
}

function Test-HermesConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Configuration
    )

    $errors = [System.Collections.Generic.List[string]]::new()

    if ($Configuration.schemaVersion -ne "1.0") {
        $errors.Add(
            "Unsupported schema version: $($Configuration.schemaVersion)"
        )
    }

    if ($null -eq $Configuration.windows) {
        $errors.Add("The 'windows' configuration section is missing.")
    }

    if ($null -eq $Configuration.taskbar) {
        $errors.Add("The 'taskbar' configuration section is missing.")
    }

    if ($null -eq $Configuration.desktop) {
        $errors.Add("The 'desktop' configuration section is missing.")
    }

    if ($null -eq $Configuration.terminal) {
        $errors.Add("The 'terminal' configuration section is missing.")
    }

    if ($null -eq $Configuration.powershell) {
        $errors.Add("The 'powershell' configuration section is missing.")
    }

    if ($null -eq $Configuration.git) {
        $errors.Add("The 'git' configuration section is missing.")
    }

    if ($null -eq $Configuration.vscode) {
        $errors.Add("The 'vscode' configuration section is missing.")
    }

    return [pscustomobject]@{
        IsValid = $errors.Count -eq 0
        Errors  = $errors
    }
}

function Show-HermesConfigurationSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Configuration
    )

    Write-Host ""
    Write-Host "Project Hermes Workstation Profile"
    Write-Host "=================================="
    Write-Host "Profile:        $($Configuration.profileName)"
    Write-Host "Schema:         $($Configuration.schemaVersion)"
    Write-Host "Description:    $($Configuration.description)"
    Write-Host ""
    Write-Host "Windows"
    Write-Host "  File extensions: $($Configuration.windows.showFileExtensions)"
    Write-Host "  Hidden files:    $($Configuration.windows.showHiddenFiles)"
    Write-Host "  Explorer target: $($Configuration.windows.launchExplorerTo)"
    Write-Host ""
    Write-Host "Taskbar"
    Write-Host "  Alignment:       $($Configuration.taskbar.alignment)"
    Write-Host "  Search mode:     $($Configuration.taskbar.searchMode)"
    Write-Host "  Widgets:         $($Configuration.taskbar.showWidgets)"
    Write-Host ""
    Write-Host "Desktop theme:     $($Configuration.desktop.theme)"
    Write-Host "Terminal setup:    $($Configuration.terminal.configureWindowsTerminal)"
    Write-Host "PowerShell setup:  $($Configuration.powershell.deployProfile)"
    Write-Host "Git setup:         $($Configuration.git.configureGit)"
    Write-Host "VS Code setup:     $($Configuration.vscode.configureVSCode)"
    Write-Host ""
}

Export-ModuleMember -Function `
    Import-HermesConfiguration, `
    Test-HermesConfiguration, `
    Show-HermesConfigurationSummary