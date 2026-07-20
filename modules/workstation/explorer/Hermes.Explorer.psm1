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

function Get-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Reads the current Windows Explorer settings managed by Hermes.

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

function Backup-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Creates a standardized backup of the current Explorer settings.

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
        Hashtable or object containing showFileExtensions, showHiddenFiles,
        and launchExplorerTo.

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

    $requiredProperties = @(
        'showFileExtensions'
        'showHiddenFiles'
        'launchExplorerTo'
    )

    foreach ($requiredProperty in $requiredProperties) {
        if ($Configuration.PSObject.Properties.Name -notcontains $requiredProperty) {
            throw "Explorer configuration is missing the required property '$requiredProperty'."
        }
    }

    $desiredLaunchValue = [string]$Configuration.launchExplorerTo

    if ($desiredLaunchValue -notin @('ThisPC', 'Home')) {
        throw "Explorer configuration property 'launchExplorerTo' must be either 'ThisPC' or 'Home'."
    }

    $currentSettings = Get-HermesExplorerSettings

    $desiredSettings = [PSCustomObject]@{
        ShowFileExtensions = [bool]$Configuration.showFileExtensions
        ShowHiddenFiles    = [bool]$Configuration.showHiddenFiles
        LaunchExplorerTo   = $desiredLaunchValue
    }

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
        Applies desired Explorer settings.

    .DESCRIPTION
        This function is intentionally not implemented until backup and
        restore workflows are complete and tested.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    throw 'Set-HermesExplorerSettings has not been implemented yet.'
}

function Restore-HermesExplorerSettings {
    <#
    .SYNOPSIS
        Restores Explorer settings from a Hermes backup.

    .DESCRIPTION
        This function is intentionally not implemented until its validation
        and rollback test suite is complete.
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
    'Backup-HermesExplorerSettings'
    'Test-HermesExplorerSettings'
    'Set-HermesExplorerSettings'
    'Restore-HermesExplorerSettings'
)
