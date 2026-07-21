Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.Windows'
$script:CanonicalProperties = @(
    'AppTheme'
    'SystemTheme'
    'Transparency'
    'AccentOnTitleBars'
)

$coreManifest = Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
$commonManifest = Join-Path $PSScriptRoot '..\..\common\Hermes.Common.psd1'

foreach ($dependency in @(
    @{ Name = 'Hermes.Core'; Path = $coreManifest }
    @{ Name = 'Hermes.Common'; Path = $commonManifest }
)) {
    if (-not (Test-Path -LiteralPath $dependency.Path -PathType Leaf)) {
        throw "$($dependency.Name) could not be found at '$($dependency.Path)'."
    }

    Import-Module $dependency.Path -Force -ErrorAction Stop
}

$script:RegistryTargets = [ordered]@{
    AppTheme = @{
        Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Name = 'AppsUseLightTheme'
        Kind = 'Theme'
    }
    SystemTheme = @{
        Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Name = 'SystemUsesLightTheme'
        Kind = 'Theme'
    }
    Transparency = @{
        Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Name = 'EnableTransparency'
        Kind = 'State'
    }
    AccentOnTitleBars = @{
        Path = 'HKCU:\Software\Microsoft\Windows\DWM'
        Name = 'ColorPrevalence'
        Kind = 'State'
    }
}

function Get-HermesWindowsRegistryState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $missing = [object]::new()
    $value = Get-HermesRegistryValue `
        -Path $Path `
        -Name $Name `
        -DefaultValue $missing

    [pscustomobject]@{
        Exists = -not [object]::ReferenceEquals($value, $missing)
        Value  = if ([object]::ReferenceEquals($value, $missing)) { $null } else { $value }
    }
}

function ConvertFrom-HermesWindowsRegistryValue {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Theme', 'State')]
        [string]$Kind,

        [Parameter(Mandatory)]
        [pscustomobject]$RegistryState
    )

    if (-not $RegistryState.Exists) {
        return 'NotConfigured'
    }

    $number = try { [int]$RegistryState.Value } catch { return 'Unknown' }

    switch ($Kind) {
        'Theme' {
            switch ($number) {
                0 { 'Dark' }
                1 { 'Light' }
                default { 'Unknown' }
            }
        }
        'State' {
            switch ($number) {
                0 { 'Disabled' }
                1 { 'Enabled' }
                default { 'Unknown' }
            }
        }
    }
}

function ConvertTo-HermesWindowsRegistryValue {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Theme', 'State')]
        [string]$Kind,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    switch ($Kind) {
        'Theme' { if ($Value -eq 'Dark') { 0 } else { 1 } }
        'State' { if ($Value -eq 'Disabled') { 0 } else { 1 } }
    }
}

function Get-HermesWindowsSettings {
    <#
    .SYNOPSIS
        Reads the Windows personalization settings managed by Project Hermes.

    .OUTPUTS
        PSCustomObject containing the canonical managed settings.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $values = [ordered]@{}

    foreach ($name in $script:CanonicalProperties) {
        $target = $script:RegistryTargets[$name]

        try {
            $state = Get-HermesWindowsRegistryState `
                -Path $target.Path `
                -Name $target.Name
        }
        catch {
            throw "Unable to read Windows setting '$name'. $($_.Exception.Message)"
        }

        $values[$name] = ConvertFrom-HermesWindowsRegistryValue `
            -Kind $target.Kind `
            -RegistryState $state
    }

    [pscustomobject]$values
}

function Test-HermesWindowsConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes a desired Windows personalization configuration.

    .PARAMETER Configuration
        Hashtable or object containing one or more supported settings.

    .OUTPUTS
        PSCustomObject containing validity, errors, and normalized configuration.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $normalized = [ordered]@{}
    $properties = @(
        if ($Configuration -is [System.Collections.IDictionary]) {
            $Configuration.Keys | ForEach-Object { [string]$_ }
        }
        else {
            $Configuration.PSObject.Properties.Name
        }
    )

    if ($properties.Count -eq 0) {
        $errors.Add('The Windows configuration must contain at least one setting.')
    }

    foreach ($property in $properties) {
        $canonical = $script:CanonicalProperties |
            Where-Object { $_ -ieq $property } |
            Select-Object -First 1

        if ($null -eq $canonical) {
            $errors.Add("Unsupported Windows setting '$property'.")
            continue
        }

        if ($normalized.Contains($canonical)) {
            $errors.Add("Windows setting '$canonical' was supplied more than once.")
            continue
        }

        $value = if ($Configuration -is [System.Collections.IDictionary]) {
            $Configuration[$property]
        }
        else {
            $Configuration.PSObject.Properties[$property].Value
        }

        $text = [string]$value
        $allowed = if ($canonical -in @('AppTheme', 'SystemTheme')) {
            @('Dark', 'Light')
        }
        else {
            @('Enabled', 'Disabled')
        }

        $matched = $allowed | Where-Object { $_ -ieq $text } | Select-Object -First 1

        if ($null -eq $matched) {
            $errors.Add("Windows setting '$canonical' must be one of: $($allowed -join ', ').")
            continue
        }

        $normalized[$canonical] = $matched
    }

    [pscustomobject]@{
        IsValid      = ($errors.Count -eq 0)
        Errors       = $errors.ToArray()
        Configuration = $normalized
    }
}

function Test-HermesWindowsSettings {
    <#
    .SYNOPSIS
        Compares current Windows personalization with desired state.

    .PARAMETER Configuration
        Desired supported Windows settings.

    .OUTPUTS
        PSCustomObject containing compliance and precise differences.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $validation = Test-HermesWindowsConfiguration -Configuration $Configuration

    if (-not $validation.IsValid) {
        throw ($validation.Errors -join ' ')
    }

    $current = Get-HermesWindowsSettings
    $differences = foreach ($name in $validation.Configuration.Keys) {
        if ($current.$name -ne $validation.Configuration[$name]) {
            [pscustomobject]@{
                Setting  = $name
                Expected = $validation.Configuration[$name]
                Actual   = $current.$name
            }
        }
    }

    [pscustomobject]@{
        PSTypeName  = 'Hermes.Windows.Compliance'
        IsCompliant = (@($differences).Count -eq 0)
        Current     = $current
        Desired     = [pscustomobject]$validation.Configuration
        Differences = @($differences)
    }
}

function Backup-HermesWindowsSettings {
    <#
    .SYNOPSIS
        Creates a standardized, lossless backup of managed Windows settings.

    .PARAMETER BackupDirectory
        Optional custom backup destination.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory
    )

    $registryMetadata = [ordered]@{}

    foreach ($name in $script:CanonicalProperties) {
        $target = $script:RegistryTargets[$name]
        $state = Get-HermesWindowsRegistryState -Path $target.Path -Name $target.Name
        $registryMetadata[$name] = @{
            Exists = $state.Exists
            Value  = $state.Value
        }
    }

    $parameters = @{
        ModuleName = $script:ModuleName
        Settings = Get-HermesWindowsSettings
        AdditionalMetadata = @{
            WindowsBackupFormat = '1.0'
            Registry = $registryMetadata
        }
    }

    if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
        $parameters.BackupDirectory = $BackupDirectory
    }

    Write-HermesBackup @parameters
}

function Set-HermesWindowsSettings {
    <#
    .SYNOPSIS
        Applies and verifies supported Windows personalization settings.

    .PARAMETER Configuration
        Desired supported Windows settings.

    .PARAMETER BackupDirectory
        Optional destination for the automatic safety backup.

    .PARAMETER SkipBackup
        Skips the automatic backup. Use only when another recovery point exists.

    .PARAMETER RestartExplorer
        Restarts Windows Explorer after successful verification.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory,

        [Parameter()]
        [switch]$SkipBackup,

        [Parameter()]
        [switch]$RestartExplorer
    )

    $validation = Test-HermesWindowsConfiguration -Configuration $Configuration

    if (-not $validation.IsValid) {
        throw ($validation.Errors -join ' ')
    }

    $before = Get-HermesWindowsSettings
    $precheck = Test-HermesWindowsSettings -Configuration $validation.Configuration

    if ($precheck.IsCompliant) {
        return [pscustomobject]@{
            PSTypeName        = 'Hermes.Windows.ChangeResult'
            Changed           = $false
            Backup            = $null
            Before            = $before
            After             = $before
            Verification      = $precheck
            ExplorerRestarted = $false
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        'Windows personalization settings',
        'Apply Hermes Windows configuration'
    )) {
        return
    }

    $backup = $null

    if (-not $SkipBackup) {
        $backupParameters = @{}
        if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
            $backupParameters.BackupDirectory = $BackupDirectory
        }
        $backup = Backup-HermesWindowsSettings @backupParameters
    }

    try {
        foreach ($name in $validation.Configuration.Keys) {
            $target = $script:RegistryTargets[$name]
            $value = ConvertTo-HermesWindowsRegistryValue `
                -Kind $target.Kind `
                -Value $validation.Configuration[$name]

            Set-HermesRegistryValue `
                -Path $target.Path `
                -Name $target.Name `
                -Value $value `
                -Type DWord `
                -CreatePath `
                -Confirm:$false |
                Out-Null
        }
    }
    catch {
        $recovery = if ($null -ne $backup) { " Restore from '$($backup.BackupPath)' if necessary." } else { '' }
        throw "Unable to apply Hermes Windows settings. $($_.Exception.Message)$recovery"
    }

    $verification = Test-HermesWindowsSettings -Configuration $validation.Configuration

    if (-not $verification.IsCompliant) {
        $details = $verification.Differences | ForEach-Object {
            "$($_.Setting): expected '$($_.Expected)', actual '$($_.Actual)'"
        }
        throw "Windows settings verification failed. $($details -join '; ')"
    }

    $restarted = $false
    if ($RestartExplorer) {
        Restart-HermesExplorer | Out-Null
        $restarted = $true
    }

    [pscustomobject]@{
        PSTypeName        = 'Hermes.Windows.ChangeResult'
        Changed           = $true
        Backup            = $backup
        Before            = $before
        After             = Get-HermesWindowsSettings
        Verification      = $verification
        ExplorerRestarted = $restarted
    }
}

function Restore-HermesWindowsSettings {
    <#
    .SYNOPSIS
        Restores managed Windows settings from a Hermes backup.

    .PARAMETER BackupPath
        Path to a Hermes.Windows backup file.

    .PARAMETER CreateSafetyBackup
        Creates a new backup before restoration.

    .PARAMETER BackupDirectory
        Optional destination for the safety backup.

    .PARAMETER RestartExplorer
        Restarts Windows Explorer after successful verification.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupPath,

        [Parameter()]
        [switch]$CreateSafetyBackup,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory,

        [Parameter()]
        [switch]$RestartExplorer
    )

    $document = Read-HermesBackup `
        -BackupPath $BackupPath `
        -ExpectedModuleName $script:ModuleName

    $hasMetadata =
        $document.PSObject.Properties.Name -contains 'AdditionalMetadata' -and
        $null -ne $document.AdditionalMetadata -and
        $document.AdditionalMetadata.PSObject.Properties.Name -contains 'Registry'

    $restorePlan = [ordered]@{}

    foreach ($name in $script:CanonicalProperties) {
        $target = $script:RegistryTargets[$name]

        if ($hasMetadata -and
            $document.AdditionalMetadata.Registry.PSObject.Properties.Name -contains $name) {
            $metadata = $document.AdditionalMetadata.Registry.$name
            $restorePlan[$name] = [pscustomobject]@{
                Exists = [bool]$metadata.Exists
                Value  = $metadata.Value
            }
            continue
        }

        if ($document.Settings.PSObject.Properties.Name -contains $name) {
            $saved = [string]$document.Settings.$name
            if ($saved -notin @('Unknown', 'NotConfigured')) {
                $restorePlan[$name] = [pscustomobject]@{
                    Exists = $true
                    Value = ConvertTo-HermesWindowsRegistryValue -Kind $target.Kind -Value $saved
                }
            }
        }
    }

    if ($restorePlan.Count -eq 0) {
        throw "The backup '$BackupPath' contains no restorable Windows settings."
    }

    $before = Get-HermesWindowsSettings
    $differences = foreach ($name in $restorePlan.Keys) {
        $target = $script:RegistryTargets[$name]
        $currentRaw = Get-HermesWindowsRegistryState -Path $target.Path -Name $target.Name
        $planned = $restorePlan[$name]
        if ($currentRaw.Exists -ne $planned.Exists -or
            ($planned.Exists -and [int]$currentRaw.Value -ne [int]$planned.Value)) {
            $name
        }
    }

    if (@($differences).Count -eq 0) {
        return [pscustomobject]@{
            PSTypeName        = 'Hermes.Windows.RestoreResult'
            Changed           = $false
            SourceBackupPath  = $BackupPath
            SafetyBackup      = $null
            Before            = $before
            After             = $before
            Verified          = $true
            ExplorerRestarted = $false
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        'Windows personalization settings',
        "Restore from '$BackupPath'"
    )) {
        return
    }

    $safetyBackup = $null
    if ($CreateSafetyBackup) {
        $parameters = @{}
        if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
            $parameters.BackupDirectory = $BackupDirectory
        }
        $safetyBackup = Backup-HermesWindowsSettings @parameters
    }

    try {
        foreach ($name in $restorePlan.Keys) {
            $target = $script:RegistryTargets[$name]
            $planned = $restorePlan[$name]

            if ($planned.Exists) {
                Set-HermesRegistryValue `
                    -Path $target.Path `
                    -Name $target.Name `
                    -Value ([int]$planned.Value) `
                    -Type DWord `
                    -CreatePath `
                    -Confirm:$false |
                    Out-Null
            }
            else {
                Remove-HermesRegistryValue `
                    -Path $target.Path `
                    -Name $target.Name `
                    -IgnoreMissing `
                    -Confirm:$false |
                    Out-Null
            }
        }
    }
    catch {
        $recovery = if ($null -ne $safetyBackup) { " Safety backup: '$($safetyBackup.BackupPath)'." } else { '' }
        throw "Unable to restore Hermes Windows settings. $($_.Exception.Message)$recovery"
    }

    $remaining = foreach ($name in $restorePlan.Keys) {
        $target = $script:RegistryTargets[$name]
        $actual = Get-HermesWindowsRegistryState -Path $target.Path -Name $target.Name
        $planned = $restorePlan[$name]
        if ($actual.Exists -ne $planned.Exists -or
            ($planned.Exists -and [int]$actual.Value -ne [int]$planned.Value)) {
            $name
        }
    }

    if (@($remaining).Count -gt 0) {
        throw "Windows restore verification failed for: $(@($remaining) -join ', ')."
    }

    $restarted = $false
    if ($RestartExplorer) {
        Restart-HermesExplorer | Out-Null
        $restarted = $true
    }

    [pscustomobject]@{
        PSTypeName        = 'Hermes.Windows.RestoreResult'
        Changed           = $true
        SourceBackupPath  = $BackupPath
        SafetyBackup      = $safetyBackup
        Before            = $before
        After             = Get-HermesWindowsSettings
        Verified          = $true
        ExplorerRestarted = $restarted
    }
}

Export-ModuleMember -Function @(
    'Get-HermesWindowsSettings'
    'Test-HermesWindowsConfiguration'
    'Test-HermesWindowsSettings'
    'Backup-HermesWindowsSettings'
    'Set-HermesWindowsSettings'
    'Restore-HermesWindowsSettings'
)
