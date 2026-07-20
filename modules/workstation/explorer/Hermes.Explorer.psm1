Set-StrictMode -Version Latest

$coreManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\..\core\Hermes.Core.psd1'

if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Hermes.Core could not be found at '$coreManifest'."
}

Import-Module `
    -Name $coreManifest `
    -Force `
    -ErrorAction Stop

$script:ExplorerAdvancedRegistryPath =
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

function ConvertTo-HermesExplorerConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $validation = Test-HermesExplorerConfiguration `
        -Configuration $Configuration

    if (-not $validation.IsValid) {
        $message = $validation.Errors -join ' '
        throw "Invalid Explorer configuration. $message"
    }

    return $validation.NormalizedConfiguration
}

function Get-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Reads the Windows Explorer settings managed by Project Hermes.

    .OUTPUTS
        PSCustomObject containing the current Explorer settings.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $registryValues = try {
        Get-ItemProperty `
            -LiteralPath $script:ExplorerAdvancedRegistryPath `
            -ErrorAction Stop
    }
    catch {
        throw "Unable to read Explorer settings from '$script:ExplorerAdvancedRegistryPath'. $($_.Exception.Message)"
    }

    $showFileExtensions = $false
    $showHiddenFiles = $false
    $launchExplorerTo = 'NotConfigured'

    if ($registryValues.PSObject.Properties.Name -contains 'HideFileExt') {
        $showFileExtensions = ([int]$registryValues.HideFileExt -eq 0)
    }

    if ($registryValues.PSObject.Properties.Name -contains 'Hidden') {
        $showHiddenFiles = ([int]$registryValues.Hidden -eq 1)
    }

    if ($registryValues.PSObject.Properties.Name -contains 'LaunchTo') {
        $launchExplorerTo = switch ([int]$registryValues.LaunchTo) {
            1 { 'ThisPC' }
            2 { 'Home' }
            default { 'Unknown' }
        }
    }

    [PSCustomObject]@{
        ShowFileExtensions = $showFileExtensions
        ShowHiddenFiles    = $showHiddenFiles
        LaunchExplorerTo   = $launchExplorerTo
    }
}

function Test-HermesExplorerConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes an Explorer configuration object.

    .PARAMETER Configuration
        Object containing showFileExtensions, showHiddenFiles, and
        launchExplorerTo.

    .OUTPUTS
        PSCustomObject containing validation status, errors, and a normalized
        configuration object.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $errors = [System.Collections.Generic.List[string]]::new()

    $requiredProperties = @(
        'showFileExtensions'
        'showHiddenFiles'
        'launchExplorerTo'
    )

    foreach ($requiredProperty in $requiredProperties) {
        if ($null -eq $Configuration.PSObject.Properties[$requiredProperty]) {
            $errors.Add(
                "The required property '$requiredProperty' is missing."
            )
        }
    }

    $normalizedConfiguration = $null

    if ($errors.Count -eq 0) {
        if ($Configuration.showFileExtensions -isnot [bool]) {
            $errors.Add(
                "The property 'showFileExtensions' must be a Boolean value."
            )
        }

        if ($Configuration.showHiddenFiles -isnot [bool]) {
            $errors.Add(
                "The property 'showHiddenFiles' must be a Boolean value."
            )
        }

        $launchExplorerTo = [string]$Configuration.launchExplorerTo

        if ($launchExplorerTo -notin @('ThisPC', 'Home')) {
            $errors.Add(
                "The property 'launchExplorerTo' must be either 'ThisPC' or 'Home'."
            )
        }

        if ($errors.Count -eq 0) {
            $normalizedConfiguration = [PSCustomObject]@{
                ShowFileExtensions = [bool]$Configuration.showFileExtensions
                ShowHiddenFiles    = [bool]$Configuration.showHiddenFiles
                LaunchExplorerTo   = $launchExplorerTo
            }
        }
    }

    [PSCustomObject]@{
        IsValid                = ($errors.Count -eq 0)
        ErrorCount             = $errors.Count
        Errors                 = $errors.ToArray()
        NormalizedConfiguration = $normalizedConfiguration
    }
}

function Backup-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Creates a standardized backup of current Explorer settings.

    .PARAMETER BackupDirectory
        Optional destination directory. When omitted, Hermes.Core writes the
        backup beneath exports\backups\explorer.

    .OUTPUTS
        PSCustomObject describing the backup that was created.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory
    )

    $currentSettings = Get-HermesExplorerSettings

    $backupParameters = @{
        ModuleName = 'Explorer'
        Settings   = $currentSettings
    }

    if (-not [string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $backupParameters.BackupDirectory = $BackupDirectory
    }

    return Write-HermesBackup @backupParameters
}

function Test-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Compares current Explorer settings with desired configuration.

    .PARAMETER Configuration
        Explorer configuration to compare with the current machine.

    .OUTPUTS
        PSCustomObject containing compliance status and differences.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $desiredSettings = ConvertTo-HermesExplorerConfiguration `
        -Configuration $Configuration

    $currentSettings = Get-HermesExplorerSettings
    $differences = [System.Collections.Generic.List[object]]::new()

    foreach ($settingName in @(
        'ShowFileExtensions'
        'ShowHiddenFiles'
        'LaunchExplorerTo'
    )) {
        $currentValue = $currentSettings.$settingName
        $desiredValue = $desiredSettings.$settingName

        if ($currentValue -ne $desiredValue) {
            $differences.Add(
                [PSCustomObject]@{
                    Setting = $settingName
                    Current = $currentValue
                    Desired = $desiredValue
                }
            )
        }
    }

    [PSCustomObject]@{
        IsCompliant     = ($differences.Count -eq 0)
        DifferenceCount = $differences.Count
        Differences     = $differences.ToArray()
        Current         = $currentSettings
        Desired         = $desiredSettings
    }
}

function Set-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Safely applies desired Windows Explorer settings.

    .DESCRIPTION
        Validates the requested configuration, compares it with the current
        state, creates a backup before making changes, writes the registry
        values, and verifies the resulting state.

        Supports -WhatIf and -Confirm through PowerShell ShouldProcess.

    .PARAMETER Configuration
        Explorer configuration to apply.

    .PARAMETER BackupDirectory
        Optional destination for the automatic pre-change backup.

    .OUTPUTS
        PSCustomObject describing the operation.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory
    )

    $desiredSettings = ConvertTo-HermesExplorerConfiguration `
        -Configuration $Configuration

    $before = Test-HermesExplorerSettings `
        -Configuration $Configuration

    if ($before.IsCompliant) {
        return [PSCustomObject]@{
            Applied                 = $false
            Planned                 = $false
            Verified                = $true
            BackupCreated           = $false
            BackupPath              = $null
            RestartExplorerRequired = $false
            Before                  = $before.Current
            After                   = $before.Current
            Desired                 = $desiredSettings
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        $script:ExplorerAdvancedRegistryPath,
        'Back up and apply Windows Explorer settings'
    )) {
        return [PSCustomObject]@{
            Applied                 = $false
            Planned                 = $true
            Verified                = $false
            BackupCreated           = $false
            BackupPath              = $null
            RestartExplorerRequired = $false
            Before                  = $before.Current
            After                   = $before.Current
            Desired                 = $desiredSettings
        }
    }

    $backupParameters = @{}

    if (-not [string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $backupParameters.BackupDirectory = $BackupDirectory
    }

    $backup = Backup-HermesExplorerSettings @backupParameters

    $hideFileExtValue = if ($desiredSettings.ShowFileExtensions) { 0 } else { 1 }
    $hiddenValue = if ($desiredSettings.ShowHiddenFiles) { 1 } else { 2 }
    $launchToValue = if ($desiredSettings.LaunchExplorerTo -eq 'ThisPC') { 1 } else { 2 }

    try {
        Set-ItemProperty `
            -LiteralPath $script:ExplorerAdvancedRegistryPath `
            -Name 'HideFileExt' `
            -Value $hideFileExtValue `
            -Type DWord `
            -ErrorAction Stop

        Set-ItemProperty `
            -LiteralPath $script:ExplorerAdvancedRegistryPath `
            -Name 'Hidden' `
            -Value $hiddenValue `
            -Type DWord `
            -ErrorAction Stop

        Set-ItemProperty `
            -LiteralPath $script:ExplorerAdvancedRegistryPath `
            -Name 'LaunchTo' `
            -Value $launchToValue `
            -Type DWord `
            -ErrorAction Stop
    }
    catch {
        throw "Unable to apply Explorer settings. A backup was created at '$($backup.BackupPath)'. $($_.Exception.Message)"
    }

    $verification = Test-HermesExplorerSettings `
        -Configuration $Configuration

    if (-not $verification.IsCompliant) {
        throw "Explorer settings were written but verification failed. Restore from '$($backup.BackupPath)' if necessary."
    }

    [PSCustomObject]@{
        Applied                 = $true
        Planned                 = $false
        Verified                = $true
        BackupCreated           = $true
        BackupPath              = $backup.BackupPath
        RestartExplorerRequired = $true
        Before                  = $before.Current
        After                   = $verification.Current
        Desired                 = $desiredSettings
    }
}

function Restore-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Restores Explorer settings from a Hermes backup.

    .DESCRIPTION
        Restore support will be implemented after the apply workflow is
        complete and validated.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupPath
    )

    throw 'Restore-HermesExplorerSettings has not been implemented yet.'
}

Export-ModuleMember -Function @(
    'Get-HermesExplorerSettings'
    'Test-HermesExplorerConfiguration'
    'Backup-HermesExplorerSettings'
    'Test-HermesExplorerSettings'
    'Set-HermesExplorerSettings'
    'Restore-HermesExplorerSettings'
)
