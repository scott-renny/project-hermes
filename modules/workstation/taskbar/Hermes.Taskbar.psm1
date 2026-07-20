Set-StrictMode -Version Latest

$script:ModuleName = 'Taskbar'

$script:Registry = @{
    Advanced      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Search        = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    CopilotPolicy = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
    StuckRects    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
}

$script:CanonicalProperties = @(
    'Alignment'
    'Search'
    'TaskView'
    'Widgets'
    'Copilot'
    'AutoHide'
    'ShowSeconds'
)

$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\..\core\Hermes.Core.psd1'

if (-not (Test-Path -LiteralPath $coreManifest)) {
    throw "Hermes.Core was not found at '$coreManifest'."
}

Import-Module -Name $coreManifest -Force -ErrorAction Stop

function Get-HermesRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

    try {
        $item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop

        return [pscustomobject]@{
            Exists = $true
            Value  = $item.$Name
        }
    }
    catch [System.Management.Automation.PSArgumentException] {
        return [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }
    catch {
        if ($_.FullyQualifiedErrorId -match 'PropertyNotFound') {
            return [pscustomobject]@{
                Exists = $false
                Value  = $null
            }
        }

        throw
    }
}

function Set-HermesRegistryDword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [int]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        $null = New-Item -Path $Path -Force -ErrorAction Stop
    }

    $null = New-ItemProperty `
        -LiteralPath $Path `
        -Name $Name `
        -PropertyType DWord `
        -Value $Value `
        -Force `
        -ErrorAction Stop
}

function ConvertTo-HermesState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Exists,

        [Parameter()]
        [AllowNull()]
        [object]$Value
    )

    if (-not $Exists) {
        return 'NotConfigured'
    }

    if ([int]$Value -eq 1) {
        return 'Enabled'
    }

    return 'Disabled'
}

function ConvertFrom-HermesState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Value
    )

    if ($Value -is [bool]) {
        return [int][bool]$Value
    }

    switch ([string]$Value) {
        'Enabled'  { return 1 }
        'Disabled' { return 0 }
        default {
            throw "Expected a Boolean value, 'Enabled', or 'Disabled'."
        }
    }
}

function ConvertTo-HermesCanonicalConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $result = [ordered]@{}
    $names = if ($Configuration -is [System.Collections.IDictionary]) {
        @($Configuration.Keys)
    }
    else {
        @($Configuration.PSObject.Properties.Name)
    }

    foreach ($name in $names) {
        $canonicalName = switch ([string]$name) {
            'ShowTaskView' { 'TaskView' }
            'ShowWidgets'  { 'Widgets' }
            'ShowCopilot'  { 'Copilot' }
            default        { [string]$name }
        }

        if ($result.Contains($canonicalName)) {
            throw "The configuration contains duplicate aliases for '$canonicalName'."
        }

        $result[$canonicalName] = $Configuration.$name
    }

    return $result
}

function Get-HermesTaskbarAutoHideState {
    [CmdletBinding()]
    param()

    $registryValue = Get-HermesRegistryValue `
        -Path $script:Registry.StuckRects `
        -Name 'Settings'

    if (-not $registryValue.Exists -or $null -eq $registryValue.Value) {
        return [pscustomobject]@{
            State     = 'NotConfigured'
            Supported = $false
            RawValue  = $null
        }
    }

    $bytes = [byte[]]$registryValue.Value

    if ($bytes.Length -le 8) {
        return [pscustomobject]@{
            State     = 'NotConfigured'
            Supported = $false
            RawValue  = $bytes
        }
    }

    return [pscustomobject]@{
        State     = if ($bytes[8] -eq 3) { 'Enabled' } else { 'Disabled' }
        Supported = $true
        RawValue  = $bytes
    }
}

function Set-HermesTaskbarAutoHideState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Value
    )

    $current = Get-HermesTaskbarAutoHideState

    if (-not $current.Supported) {
        throw 'Windows taskbar AutoHide data is unavailable or invalid.'
    }

    $enabled = ConvertFrom-HermesState -Value $Value
    $bytes = [byte[]]$current.RawValue.Clone()
    $bytes[8] = if ($enabled -eq 1) { 3 } else { 2 }

    $null = New-ItemProperty `
        -LiteralPath $script:Registry.StuckRects `
        -Name 'Settings' `
        -PropertyType Binary `
        -Value $bytes `
        -Force `
        -ErrorAction Stop
}

function Restart-HermesExplorer {
    [CmdletBinding()]
    param()

    Get-Process -Name explorer -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction Stop

    Start-Process -FilePath 'explorer.exe' -ErrorAction Stop
}

function Get-HermesTaskbarSettings {
    <#
    .SYNOPSIS
        Gets the current Windows taskbar configuration managed by Hermes.

    .OUTPUTS
        Hermes.Taskbar.Settings
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $alignment = Get-HermesRegistryValue `
        -Path $script:Registry.Advanced `
        -Name 'TaskbarAl'

    $search = Get-HermesRegistryValue `
        -Path $script:Registry.Search `
        -Name 'SearchboxTaskbarMode'

    $taskView = Get-HermesRegistryValue `
        -Path $script:Registry.Advanced `
        -Name 'ShowTaskViewButton'

    $widgets = Get-HermesRegistryValue `
        -Path $script:Registry.Advanced `
        -Name 'TaskbarDa'

    $copilot = Get-HermesRegistryValue `
        -Path $script:Registry.CopilotPolicy `
        -Name 'TurnOffWindowsCopilot'

    $seconds = Get-HermesRegistryValue `
        -Path $script:Registry.Advanced `
        -Name 'ShowSecondsInSystemClock'

    $autoHide = Get-HermesTaskbarAutoHideState

    [pscustomobject]@{
        PSTypeName  = 'Hermes.Taskbar.Settings'
        Alignment   = if (-not $alignment.Exists) {
            'NotConfigured'
        }
        else {
            switch ([int]$alignment.Value) {
                0 { 'Left' }
                1 { 'Center' }
                default { 'Unknown' }
            }
        }
        Search      = if (-not $search.Exists) {
            'NotConfigured'
        }
        else {
            switch ([int]$search.Value) {
                0 { 'Hidden' }
                1 { 'Icon' }
                2 { 'Box' }
                3 { 'IconAndLabel' }
                default { 'Unknown' }
            }
        }
        TaskView    = ConvertTo-HermesState `
            -Exists $taskView.Exists `
            -Value $taskView.Value
        Widgets     = ConvertTo-HermesState `
            -Exists $widgets.Exists `
            -Value $widgets.Value
        Copilot     = if (-not $copilot.Exists) {
            'NotConfigured'
        }
        elseif ([int]$copilot.Value -eq 1) {
            'Disabled'
        }
        else {
            'Enabled'
        }
        AutoHide    = $autoHide.State
        ShowSeconds = ConvertTo-HermesState `
            -Exists $seconds.Exists `
            -Value $seconds.Value
    }
}

function Test-HermesTaskbarConfiguration {
    <#
    .SYNOPSIS
        Validates a desired Hermes taskbar configuration.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    try {
        $canonical = ConvertTo-HermesCanonicalConfiguration `
            -Configuration $Configuration
    }
    catch {
        return [pscustomobject]@{
            PSTypeName    = 'Hermes.Taskbar.ConfigurationValidation'
            IsValid       = $false
            Errors        = @($_.Exception.Message)
            Configuration = $null
        }
    }

    $errors = [System.Collections.Generic.List[string]]::new()

    if ($canonical.Count -eq 0) {
        $errors.Add('The configuration must contain at least one supported setting.')
    }

    foreach ($name in $canonical.Keys) {
        if ($script:CanonicalProperties -notcontains $name) {
            $errors.Add("Unsupported taskbar setting '$name'.")
        }
    }

    if (
        $canonical.Contains('Alignment') -and
        [string]$canonical.Alignment -notin @('Left', 'Center')
    ) {
        $errors.Add("Alignment must be 'Left' or 'Center'.")
    }

    if (
        $canonical.Contains('Search') -and
        [string]$canonical.Search -notin @(
            'Hidden'
            'Icon'
            'Box'
            'IconAndLabel'
        )
    ) {
        $errors.Add(
            "Search must be 'Hidden', 'Icon', 'Box', or 'IconAndLabel'."
        )
    }

    foreach ($name in @(
        'TaskView'
        'Widgets'
        'Copilot'
        'AutoHide'
        'ShowSeconds'
    )) {
        if ($canonical.Contains($name)) {
            $value = $canonical[$name]

            if (
                $value -isnot [bool] -and
                [string]$value -notin @('Enabled', 'Disabled')
            ) {
                $errors.Add(
                    "$name must be a Boolean value, 'Enabled', or 'Disabled'."
                )
            }
        }
    }

    [pscustomobject]@{
        PSTypeName    = 'Hermes.Taskbar.ConfigurationValidation'
        IsValid       = ($errors.Count -eq 0)
        Errors        = $errors.ToArray()
        Configuration = $canonical
    }
}

function Test-HermesTaskbarSettings {
    <#
    .SYNOPSIS
        Compares current taskbar settings with a desired configuration.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Configuration
    )

    $validation = Test-HermesTaskbarConfiguration `
        -Configuration $Configuration

    if (-not $validation.IsValid) {
        throw ($validation.Errors -join ' ')
    }

    $current = Get-HermesTaskbarSettings
    $differences = foreach ($name in $validation.Configuration.Keys) {
        $expected = $validation.Configuration[$name]

        if ($expected -is [bool]) {
            $expected = if ($expected) { 'Enabled' } else { 'Disabled' }
        }

        $actual = $current.$name

        if ($actual -ne $expected) {
            [pscustomobject]@{
                Setting  = $name
                Expected = $expected
                Actual   = $actual
            }
        }
    }

    [pscustomobject]@{
        PSTypeName  = 'Hermes.Taskbar.Compliance'
        IsCompliant = (@($differences).Count -eq 0)
        Current     = $current
        Differences = @($differences)
    }
}

function Backup-HermesTaskbarSettings {
    <#
    .SYNOPSIS
        Creates a standardized Hermes backup of current taskbar settings.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory
    )

    $parameters = @{
        ModuleName = $script:ModuleName
        Settings   = Get-HermesTaskbarSettings
    }

    if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
        $parameters.BackupDirectory = $BackupDirectory
    }

    Write-HermesBackup @parameters
}

function Set-HermesTaskbarSettings {
    <#
    .SYNOPSIS
        Applies and verifies a desired Windows taskbar configuration.
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

    $validation = Test-HermesTaskbarConfiguration `
        -Configuration $Configuration

    if (-not $validation.IsValid) {
        throw ($validation.Errors -join ' ')
    }

    $desired = $validation.Configuration
    $before = Get-HermesTaskbarSettings
    $precheck = Test-HermesTaskbarSettings -Configuration $desired

    if ($precheck.IsCompliant) {
        return [pscustomobject]@{
            PSTypeName         = 'Hermes.Taskbar.ChangeResult'
            Changed            = $false
            Backup             = $null
            Before             = $before
            After              = $before
            Verification       = $precheck
            ExplorerRestarted  = $false
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        'Windows taskbar settings',
        'Apply Hermes taskbar configuration'
    )) {
        return
    }

    $backup = $null

    if (-not $SkipBackup) {
        $backupParameters = @{}

        if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
            $backupParameters.BackupDirectory = $BackupDirectory
        }

        $backup = Backup-HermesTaskbarSettings @backupParameters
    }

    try {
        foreach ($name in $desired.Keys) {
            switch ($name) {
                'Alignment' {
                    Set-HermesRegistryDword `
                        -Path $script:Registry.Advanced `
                        -Name 'TaskbarAl' `
                        -Value $(if ($desired[$name] -eq 'Left') { 0 } else { 1 })
                }

                'Search' {
                    $value = switch ($desired[$name]) {
                        'Hidden'       { 0 }
                        'Icon'         { 1 }
                        'Box'          { 2 }
                        'IconAndLabel' { 3 }
                    }

                    Set-HermesRegistryDword `
                        -Path $script:Registry.Search `
                        -Name 'SearchboxTaskbarMode' `
                        -Value $value
                }

                'TaskView' {
                    Set-HermesRegistryDword `
                        -Path $script:Registry.Advanced `
                        -Name 'ShowTaskViewButton' `
                        -Value (ConvertFrom-HermesState $desired[$name])
                }

                'Widgets' {
                    Set-HermesRegistryDword `
                        -Path $script:Registry.Advanced `
                        -Name 'TaskbarDa' `
                        -Value (ConvertFrom-HermesState $desired[$name])
                }

                'Copilot' {
                    $enabled = ConvertFrom-HermesState $desired[$name]

                    Set-HermesRegistryDword `
                        -Path $script:Registry.CopilotPolicy `
                        -Name 'TurnOffWindowsCopilot' `
                        -Value $(if ($enabled -eq 1) { 0 } else { 1 })
                }

                'AutoHide' {
                    Set-HermesTaskbarAutoHideState `
                        -Value $desired[$name]
                }

                'ShowSeconds' {
                    Set-HermesRegistryDword `
                        -Path $script:Registry.Advanced `
                        -Name 'ShowSecondsInSystemClock' `
                        -Value (ConvertFrom-HermesState $desired[$name])
                }
            }
        }
    }
    catch {
        throw "Unable to apply Hermes taskbar settings. $($_.Exception.Message)"
    }

    $verification = Test-HermesTaskbarSettings -Configuration $desired

    if (-not $verification.IsCompliant) {
        $details = $verification.Differences |
            ForEach-Object {
                "$($_.Setting): expected '$($_.Expected)', actual '$($_.Actual)'"
            }

        throw "Taskbar verification failed. $($details -join '; ')"
    }

    $restarted = $false

    if ($RestartExplorer) {
        Restart-HermesExplorer
        $restarted = $true
    }

    [pscustomobject]@{
        PSTypeName         = 'Hermes.Taskbar.ChangeResult'
        Changed            = $true
        Backup             = $backup
        Before             = $before
        After              = Get-HermesTaskbarSettings
        Verification       = $verification
        ExplorerRestarted  = $restarted
    }
}

function Restore-HermesTaskbarSettings {
    <#
    .SYNOPSIS
        Restores taskbar settings from a Hermes backup.
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

    $settings = $document.Settings
    $configuration = [ordered]@{}

    foreach ($name in $script:CanonicalProperties) {
        if (
            $settings.PSObject.Properties.Name -contains $name -and
            $null -ne $settings.$name -and
            $settings.$name -notin @('NotConfigured', 'Unknown')
        ) {
            $configuration[$name] = $settings.$name
        }
    }

    if ($configuration.Count -eq 0) {
        throw "The backup '$BackupPath' contains no restorable taskbar settings."
    }

    $precheck = Test-HermesTaskbarSettings `
        -Configuration $configuration

    if ($precheck.IsCompliant) {
        return [pscustomobject]@{
            PSTypeName         = 'Hermes.Taskbar.RestoreResult'
            Changed            = $false
            SourceBackupPath   = $BackupPath
            SafetyBackup       = $null
            Verification       = $precheck
            ExplorerRestarted  = $false
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        'Windows taskbar settings',
        "Restore from '$BackupPath'"
    )) {
        return
    }

    $safetyBackup = $null

    if ($CreateSafetyBackup) {
        $backupParameters = @{}

        if ($PSBoundParameters.ContainsKey('BackupDirectory')) {
            $backupParameters.BackupDirectory = $BackupDirectory
        }

        $safetyBackup = Backup-HermesTaskbarSettings @backupParameters
    }

    $setParameters = @{
        Configuration  = $configuration
        SkipBackup     = $true
        Confirm        = $false
        RestartExplorer = $RestartExplorer
    }

    $result = Set-HermesTaskbarSettings @setParameters

    [pscustomobject]@{
        PSTypeName         = 'Hermes.Taskbar.RestoreResult'
        Changed            = $result.Changed
        SourceBackupPath   = $BackupPath
        SafetyBackup       = $safetyBackup
        Verification       = $result.Verification
        ExplorerRestarted  = $result.ExplorerRestarted
    }
}

Export-ModuleMember -Function @(
    'Get-HermesTaskbarSettings'
    'Test-HermesTaskbarConfiguration'
    'Test-HermesTaskbarSettings'
    'Backup-HermesTaskbarSettings'
    'Set-HermesTaskbarSettings'
    'Restore-HermesTaskbarSettings'
)
