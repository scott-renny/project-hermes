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

$commonManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\..\common\Hermes.Common.psd1'

if (-not (Test-Path -LiteralPath $commonManifest -PathType Leaf)) {
    throw "Hermes.Common could not be found at '$commonManifest'."
}

Import-Module `
    -Name $commonManifest `
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

    $missingValue = [object]::new()

    try {
        $hideFileExt = Get-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'HideFileExt' `
            -DefaultValue $missingValue

        $hidden = Get-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'Hidden' `
            -DefaultValue $missingValue

        $launchTo = Get-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'LaunchTo' `
            -DefaultValue $missingValue
    }
    catch {
        throw "Unable to read Explorer settings from '$script:ExplorerAdvancedRegistryPath'. $($_.Exception.Message)"
    }

    $showFileExtensions = if ([object]::ReferenceEquals($hideFileExt, $missingValue)) {
        $false
    }
    else {
        ([int]$hideFileExt -eq 0)
    }

    $showHiddenFiles = if ([object]::ReferenceEquals($hidden, $missingValue)) {
        $false
    }
    else {
        ([int]$hidden -eq 1)
    }

    $launchExplorerTo = if ([object]::ReferenceEquals($launchTo, $missingValue)) {
        'NotConfigured'
    }
    else {
        switch ([int]$launchTo) {
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
        $propertyExists = if ($Configuration -is [System.Collections.IDictionary]) {
            @($Configuration.Keys) -icontains $requiredProperty
        }
        else {
            $null -ne $Configuration.PSObject.Properties[$requiredProperty]
        }

        if (-not $propertyExists) {
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
        Set-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'HideFileExt' `
            -Value $hideFileExtValue `
            -Type DWord `
            -CreatePath `
            -Confirm:$false `
            -ErrorAction Stop

        Set-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'Hidden' `
            -Value $hiddenValue `
            -Type DWord `
            -CreatePath `
            -Confirm:$false `
            -ErrorAction Stop

        Set-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'LaunchTo' `
            -Value $launchToValue `
            -Type DWord `
            -CreatePath `
            -Confirm:$false `
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
        Reads and validates a standardized Hermes backup, confirms that it
        belongs to the Explorer module, creates a new safety backup, restores
        the saved registry state, and verifies the result.

        Supports backups where LaunchExplorerTo was not configured. In that
        case, the LaunchTo registry value is removed rather than replaced with
        a guessed value.

    .PARAMETER BackupPath
        Path to a Hermes Explorer backup JSON file.

    .PARAMETER SafetyBackupDirectory
        Optional destination for the pre-restore safety backup.

    .OUTPUTS
        PSCustomObject describing the restore operation.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SafetyBackupDirectory
    )

    $resolvedBackupPath = try {
        (Resolve-Path -LiteralPath $BackupPath -ErrorAction Stop).Path
    }
    catch {
        throw "Explorer backup could not be found at '$BackupPath'. $($_.Exception.Message)"
    }

    $backup = try {
        Read-HermesBackup -BackupPath $resolvedBackupPath
    }
    catch {
        throw "Unable to read Explorer backup '$resolvedBackupPath'. $($_.Exception.Message)"
    }

    if ($null -eq $backup) {
        throw "Hermes.Core returned no backup data for '$resolvedBackupPath'."
    }

    $moduleProperty = $backup.PSObject.Properties['ModuleName']

    if ($null -eq $moduleProperty) {
        $moduleProperty = $backup.PSObject.Properties['Module']
    }

    if ($null -eq $moduleProperty -or
        [string]::IsNullOrWhiteSpace([string]$moduleProperty.Value)) {
        throw "Backup '$resolvedBackupPath' does not identify its Hermes module."
    }

    $backupModuleName = [string]$moduleProperty.Value

    if ($backupModuleName -ne 'Explorer' -and
        $backupModuleName -ne 'Hermes.Explorer') {
        throw "Backup '$resolvedBackupPath' belongs to module '$backupModuleName', not Explorer."
    }

    $settingsProperty = $backup.PSObject.Properties['Settings']

    if ($null -eq $settingsProperty -or $null -eq $settingsProperty.Value) {
        throw "Backup '$resolvedBackupPath' does not contain Explorer settings."
    }

    $savedSettings = $settingsProperty.Value

    foreach ($requiredSetting in @(
        'ShowFileExtensions'
        'ShowHiddenFiles'
        'LaunchExplorerTo'
    )) {
        if ($null -eq $savedSettings.PSObject.Properties[$requiredSetting]) {
            throw "Backup '$resolvedBackupPath' is missing the Explorer setting '$requiredSetting'."
        }
    }

    if ($savedSettings.ShowFileExtensions -isnot [bool]) {
        throw "Backup '$resolvedBackupPath' contains an invalid ShowFileExtensions value."
    }

    if ($savedSettings.ShowHiddenFiles -isnot [bool]) {
        throw "Backup '$resolvedBackupPath' contains an invalid ShowHiddenFiles value."
    }

    $launchExplorerTo = [string]$savedSettings.LaunchExplorerTo

    if ($launchExplorerTo -notin @('ThisPC', 'Home', 'NotConfigured')) {
        throw "Backup '$resolvedBackupPath' contains an invalid LaunchExplorerTo value '$launchExplorerTo'."
    }

    $restoreSettings = [PSCustomObject]@{
        ShowFileExtensions = [bool]$savedSettings.ShowFileExtensions
        ShowHiddenFiles    = [bool]$savedSettings.ShowHiddenFiles
        LaunchExplorerTo   = $launchExplorerTo
    }

    $before = Get-HermesExplorerSettings
    $alreadyRestored = (
        $before.ShowFileExtensions -eq $restoreSettings.ShowFileExtensions -and
        $before.ShowHiddenFiles -eq $restoreSettings.ShowHiddenFiles -and
        $before.LaunchExplorerTo -eq $restoreSettings.LaunchExplorerTo
    )

    if ($alreadyRestored) {
        return [PSCustomObject]@{
            Restored                = $false
            Planned                 = $false
            Verified                = $true
            SourceBackupPath        = $resolvedBackupPath
            SafetyBackupCreated     = $false
            SafetyBackupPath        = $null
            RestartExplorerRequired = $false
            Before                  = $before
            After                   = $before
            RestoredSettings        = $restoreSettings
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        $script:ExplorerAdvancedRegistryPath,
        "Create a safety backup and restore Windows Explorer settings from '$resolvedBackupPath'"
    )) {
        return [PSCustomObject]@{
            Restored                = $false
            Planned                 = $true
            Verified                = $false
            SourceBackupPath        = $resolvedBackupPath
            SafetyBackupCreated     = $false
            SafetyBackupPath        = $null
            RestartExplorerRequired = $false
            Before                  = $before
            After                   = $before
            RestoredSettings        = $restoreSettings
        }
    }

    $backupParameters = @{}

    if (-not [string]::IsNullOrWhiteSpace($SafetyBackupDirectory)) {
        $backupParameters.BackupDirectory = $SafetyBackupDirectory
    }

    $safetyBackup = Backup-HermesExplorerSettings @backupParameters
    $hideFileExtValue = if ($restoreSettings.ShowFileExtensions) { 0 } else { 1 }
    $hiddenValue = if ($restoreSettings.ShowHiddenFiles) { 1 } else { 2 }

    try {
        Set-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'HideFileExt' `
            -Value $hideFileExtValue `
            -Type DWord `
            -CreatePath `
            -Confirm:$false `
            -ErrorAction Stop

        Set-HermesRegistryValue `
            -Path $script:ExplorerAdvancedRegistryPath `
            -Name 'Hidden' `
            -Value $hiddenValue `
            -Type DWord `
            -CreatePath `
            -Confirm:$false `
            -ErrorAction Stop

        switch ($restoreSettings.LaunchExplorerTo) {
            'ThisPC' {
                Set-HermesRegistryValue `
                    -Path $script:ExplorerAdvancedRegistryPath `
                    -Name 'LaunchTo' `
                    -Value 1 `
                    -Type DWord `
                    -CreatePath `
                    -Confirm:$false `
                    -ErrorAction Stop
            }

            'Home' {
                Set-HermesRegistryValue `
                    -Path $script:ExplorerAdvancedRegistryPath `
                    -Name 'LaunchTo' `
                    -Value 2 `
                    -Type DWord `
                    -CreatePath `
                    -Confirm:$false `
                    -ErrorAction Stop
            }

            'NotConfigured' {
                Remove-HermesRegistryValue `
                    -Path $script:ExplorerAdvancedRegistryPath `
                    -Name 'LaunchTo' `
                    -IgnoreMissing `
                    -Confirm:$false `
                    -ErrorAction Stop
            }
        }
    }
    catch {
        throw "Unable to restore Explorer settings. A safety backup was created at '$($safetyBackup.BackupPath)'. $($_.Exception.Message)"
    }

    $after = Get-HermesExplorerSettings
    $verified = (
        $after.ShowFileExtensions -eq $restoreSettings.ShowFileExtensions -and
        $after.ShowHiddenFiles -eq $restoreSettings.ShowHiddenFiles -and
        $after.LaunchExplorerTo -eq $restoreSettings.LaunchExplorerTo
    )

    if (-not $verified) {
        throw "Explorer restore completed but verification failed. Restore the safety backup at '$($safetyBackup.BackupPath)' if necessary."
    }

    [PSCustomObject]@{
        Restored                = $true
        Planned                 = $false
        Verified                = $true
        SourceBackupPath        = $resolvedBackupPath
        SafetyBackupCreated     = $true
        SafetyBackupPath        = $safetyBackup.BackupPath
        RestartExplorerRequired = $true
        Before                  = $before
        After                   = $after
        RestoredSettings        = $restoreSettings
    }
}

Export-ModuleMember -Function @(
    'Get-HermesExplorerSettings'
    'Test-HermesExplorerConfiguration'
    'Backup-HermesExplorerSettings'
    'Test-HermesExplorerSettings'
    'Set-HermesExplorerSettings'
    'Restore-HermesExplorerSettings'
)
