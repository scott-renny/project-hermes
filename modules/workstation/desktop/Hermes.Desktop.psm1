Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.Desktop'
$script:CanonicalProperties = @('WallpaperPath', 'WallpaperStyle', 'DesktopIcons')
$script:DesktopPath = 'HKCU:\Control Panel\Desktop'
$script:ExplorerAdvancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

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

function Get-HermesDesktopRegistryState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    $missing = [object]::new()
    $value = Get-HermesRegistryValue -Path $Path -Name $Name -DefaultValue $missing

    [pscustomobject]@{
        Exists = -not [object]::ReferenceEquals($value, $missing)
        Value  = if ([object]::ReferenceEquals($value, $missing)) { $null } else { $value }
    }
}

function ConvertFrom-HermesWallpaperStyle {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][pscustomobject]$Style,
        [Parameter(Mandatory)][pscustomobject]$Tile
    )

    if (-not $Style.Exists -and -not $Tile.Exists) { return 'NotConfigured' }
    if (-not $Style.Exists -or -not $Tile.Exists) { return 'Unknown' }

    $key = '{0}:{1}' -f [string]$Style.Value, [string]$Tile.Value
    switch ($key) {
        '10:0' { 'Fill' }
        '6:0'  { 'Fit' }
        '2:0'  { 'Stretch' }
        '0:0'  { 'Center' }
        '0:1'  { 'Tile' }
        '22:0' { 'Span' }
        default { 'Unknown' }
    }
}

function Get-HermesWallpaperStyleValues {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$Style)

    switch ($Style) {
        'Fill'    { @{ WallpaperStyle = '10'; TileWallpaper = '0' } }
        'Fit'     { @{ WallpaperStyle = '6';  TileWallpaper = '0' } }
        'Stretch' { @{ WallpaperStyle = '2';  TileWallpaper = '0' } }
        'Center'  { @{ WallpaperStyle = '0';  TileWallpaper = '0' } }
        'Tile'    { @{ WallpaperStyle = '0';  TileWallpaper = '1' } }
        'Span'    { @{ WallpaperStyle = '22'; TileWallpaper = '0' } }
        default   { throw "Unsupported wallpaper style '$Style'." }
    }
}

function Invoke-HermesDesktopRefresh {
    [CmdletBinding()]
    param()

    if (-not ('Hermes.NativeMethods' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Hermes {
    public static class NativeMethods {
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SystemParametersInfo(
            int action, int parameter, string value, int flags);
    }
}
'@
    }

    $wallpaper = [string](Get-HermesRegistryValue -Path $script:DesktopPath -Name 'WallPaper' -DefaultValue '')
    $updated = [Hermes.NativeMethods]::SystemParametersInfo(20, 0, $wallpaper, 3)
    if (-not $updated) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "Windows did not refresh the desktop wallpaper. Win32 error: $code."
    }
}

function Get-HermesDesktopSettings {
    <#
    .SYNOPSIS
        Reads the native Windows desktop settings managed by Project Hermes.
    .OUTPUTS
        PSCustomObject containing wallpaper path, wallpaper style, and desktop-icon visibility.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        $wallpaper = Get-HermesDesktopRegistryState -Path $script:DesktopPath -Name 'WallPaper'
        $style = Get-HermesDesktopRegistryState -Path $script:DesktopPath -Name 'WallpaperStyle'
        $tile = Get-HermesDesktopRegistryState -Path $script:DesktopPath -Name 'TileWallpaper'
        $hideIcons = Get-HermesDesktopRegistryState -Path $script:ExplorerAdvancedPath -Name 'HideIcons'
    }
    catch {
        throw "Unable to read Hermes desktop settings. $($_.Exception.Message)"
    }

    $iconState = if (-not $hideIcons.Exists) {
        'NotConfigured'
    }
    else {
        switch ([int]$hideIcons.Value) { 0 { 'Shown' } 1 { 'Hidden' } default { 'Unknown' } }
    }

    [pscustomobject]@{
        WallpaperPath  = if ($wallpaper.Exists -and -not [string]::IsNullOrWhiteSpace([string]$wallpaper.Value)) { [string]$wallpaper.Value } elseif ($wallpaper.Exists) { 'None' } else { 'NotConfigured' }
        WallpaperStyle = ConvertFrom-HermesWallpaperStyle -Style $style -Tile $tile
        DesktopIcons   = $iconState
    }
}

function Test-HermesDesktopConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes a desired Hermes desktop configuration.
    .PARAMETER Configuration
        Hashtable or object containing one or more supported desktop settings.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $normalized = [ordered]@{}
    $properties = @(
        if ($Configuration -is [Collections.IDictionary]) { $Configuration.Keys | ForEach-Object { [string]$_ } }
        else { $Configuration.PSObject.Properties.Name }
    )

    if ($properties.Count -eq 0) { $errors.Add('Desktop configuration cannot be empty.') }

    foreach ($name in $properties) {
        if ($script:CanonicalProperties -notcontains $name) {
            $errors.Add("Unsupported desktop setting '$name'.")
            continue
        }

        $value = if ($Configuration -is [Collections.IDictionary]) { $Configuration[$name] } else { $Configuration.$name }
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
            $errors.Add("Desktop setting '$name' requires a value.")
            continue
        }

        switch ($name) {
            'WallpaperPath' {
                $candidate = [Environment]::ExpandEnvironmentVariables([string]$value)
                if (-not [IO.Path]::IsPathFullyQualified($candidate)) {
                    try {
                        $candidate = Join-Path `
                            -Path (Get-HermesRepositoryRoot) `
                            -ChildPath $candidate
                    }
                    catch {
                        $errors.Add("Unable to resolve repository-relative WallpaperPath '$value'. $($_.Exception.Message)")
                        continue
                    }
                }

                $candidate = [IO.Path]::GetFullPath($candidate)

                if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                    $errors.Add("Wallpaper file does not exist: '$candidate'.")
                }
                else { $normalized[$name] = $candidate }
            }
            'WallpaperStyle' {
                $match = @(
                    @('Fill', 'Fit', 'Stretch', 'Center', 'Tile', 'Span') |
                        Where-Object { $_ -ieq [string]$value }
                )
                if ($match.Count -ne 1) { $errors.Add("WallpaperStyle must be Fill, Fit, Stretch, Center, Tile, or Span.") }
                else { $normalized[$name] = $match[0] }
            }
            'DesktopIcons' {
                $match = @(
                    @('Shown', 'Hidden') |
                        Where-Object { $_ -ieq [string]$value }
                )
                if ($match.Count -ne 1) { $errors.Add('DesktopIcons must be Shown or Hidden.') }
                else { $normalized[$name] = $match[0] }
            }
        }
    }

    [pscustomobject]@{
        IsValid       = ($errors.Count -eq 0)
        Errors        = @($errors)
        Configuration = $normalized
    }
}

function Test-HermesDesktopSettings {
    <#
    .SYNOPSIS
        Compares native Windows desktop state with a desired configuration.
    .PARAMETER Configuration
        Desired Hermes desktop configuration.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $validation = Test-HermesDesktopConfiguration -Configuration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }

    $current = Get-HermesDesktopSettings
    $differences = @(
        foreach ($name in $validation.Configuration.Keys) {
            if ([string]$current.$name -ine [string]$validation.Configuration[$name]) {
                [pscustomobject]@{ Setting = $name; Expected = $validation.Configuration[$name]; Actual = $current.$name }
            }
        }
    )

    [pscustomobject]@{
        IsCompliant = ($differences.Count -eq 0)
        Current     = $current
        Desired     = [pscustomobject]$validation.Configuration
        Differences = $differences
    }
}

function Backup-HermesDesktopSettings {
    <#
    .SYNOPSIS
        Creates a standardized backup of the current native Windows desktop state.
    .PARAMETER BackupDirectory
        Optional destination for the generated Hermes backup.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter()][ValidateNotNullOrEmpty()][string]$BackupDirectory)

    $raw = [ordered]@{}
    foreach ($target in @(
        @{ Key = 'WallPaper'; Path = $script:DesktopPath; Name = 'WallPaper' }
        @{ Key = 'WallpaperStyle'; Path = $script:DesktopPath; Name = 'WallpaperStyle' }
        @{ Key = 'TileWallpaper'; Path = $script:DesktopPath; Name = 'TileWallpaper' }
        @{ Key = 'HideIcons'; Path = $script:ExplorerAdvancedPath; Name = 'HideIcons' }
    )) {
        $state = Get-HermesDesktopRegistryState -Path $target.Path -Name $target.Name
        $raw[$target.Key] = @{ Exists = $state.Exists; Value = $state.Value }
    }

    $parameters = @{
        ModuleName = $script:ModuleName
        Settings = Get-HermesDesktopSettings
        AdditionalMetadata = @{ DesktopBackupFormat = '1.0'; Registry = $raw }
    }
    if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $parameters.BackupDirectory = $BackupDirectory }
    Write-HermesBackup @parameters
}

function Set-HermesDesktopSettings {
    <#
    .SYNOPSIS
        Applies and verifies a desired native Windows desktop configuration.
    .PARAMETER Configuration
        Desired Hermes desktop configuration.
    .PARAMETER BackupDirectory
        Optional destination for the automatic safety backup.
    .PARAMETER SkipBackup
        Suppresses the automatic backup. Use only when another recovery point exists.
    .PARAMETER RestartExplorer
        Restarts Explorer after applying desktop-icon visibility.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateNotNull()][object]$Configuration,
        [Parameter()][ValidateNotNullOrEmpty()][string]$BackupDirectory,
        [Parameter()][switch]$SkipBackup,
        [Parameter()][switch]$RestartExplorer
    )

    $validation = Test-HermesDesktopConfiguration -Configuration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }

    $before = Get-HermesDesktopSettings
    $precheck = Test-HermesDesktopSettings -Configuration $validation.Configuration
    if ($precheck.IsCompliant) {
        return [pscustomobject]@{ Changed = $false; Backup = $null; Before = $before; After = $before; Verification = $precheck; ExplorerRestarted = $false }
    }

    if (-not $PSCmdlet.ShouldProcess('Windows desktop settings', 'Apply Hermes desktop configuration')) { return }

    $backup = $null
    if (-not $SkipBackup) {
        $backupParameters = @{}
        if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $backupParameters.BackupDirectory = $BackupDirectory }
        $backup = Backup-HermesDesktopSettings @backupParameters
    }

    try {
        foreach ($name in $validation.Configuration.Keys) {
            switch ($name) {
                'WallpaperPath' {
                    Set-HermesRegistryValue -Path $script:DesktopPath -Name 'WallPaper' -Value $validation.Configuration[$name] -Type String -CreatePath -Confirm:$false | Out-Null
                }
                'WallpaperStyle' {
                    $values = Get-HermesWallpaperStyleValues -Style $validation.Configuration[$name]
                    Set-HermesRegistryValue -Path $script:DesktopPath -Name 'WallpaperStyle' -Value $values.WallpaperStyle -Type String -CreatePath -Confirm:$false | Out-Null
                    Set-HermesRegistryValue -Path $script:DesktopPath -Name 'TileWallpaper' -Value $values.TileWallpaper -Type String -CreatePath -Confirm:$false | Out-Null
                }
                'DesktopIcons' {
                    $hide = if ($validation.Configuration[$name] -eq 'Hidden') { 1 } else { 0 }
                    Set-HermesRegistryValue -Path $script:ExplorerAdvancedPath -Name 'HideIcons' -Value $hide -Type DWord -CreatePath -Confirm:$false | Out-Null
                }
            }
        }

        if ($validation.Configuration.Contains('WallpaperPath') -or $validation.Configuration.Contains('WallpaperStyle')) {
            Invoke-HermesDesktopRefresh
        }
    }
    catch {
        $backupContext = if ($null -ne $backup) { " Safety backup: '$($backup.BackupPath)'." } else { '' }
        throw "Unable to apply Hermes desktop settings. $($_.Exception.Message)$backupContext"
    }

    $explorerRestarted = $false
    if ($RestartExplorer -and $validation.Configuration.Contains('DesktopIcons')) {
        Restart-HermesExplorer -Confirm:$false | Out-Null
        $explorerRestarted = $true
    }

    $verification = Test-HermesDesktopSettings -Configuration $validation.Configuration
    if (-not $verification.IsCompliant) { throw 'Hermes desktop post-change verification failed.' }

    [pscustomobject]@{
        Changed = $true
        Backup = $backup
        Before = $before
        After = Get-HermesDesktopSettings
        Verification = $verification
        ExplorerRestarted = $explorerRestarted
    }
}

function Restore-HermesDesktopSettings {
    <#
    .SYNOPSIS
        Restores native Windows desktop settings from a Hermes backup.
    .PARAMETER BackupPath
        Path to a backup created by Hermes.Desktop.
    .PARAMETER CreateSafetyBackup
        Creates a new backup before restoration.
    .PARAMETER BackupDirectory
        Optional destination for the safety backup.
    .PARAMETER RestartExplorer
        Restarts Explorer after restoration.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BackupPath,
        [Parameter()][switch]$CreateSafetyBackup,
        [Parameter()][ValidateNotNullOrEmpty()][string]$BackupDirectory,
        [Parameter()][switch]$RestartExplorer
    )

    $document = Read-HermesBackup -BackupPath $BackupPath -ExpectedModuleName $script:ModuleName
    if (-not ($document.PSObject.Properties.Name -contains 'AdditionalMetadata') -or
        -not ($document.AdditionalMetadata.PSObject.Properties.Name -contains 'Registry')) {
        throw "The backup '$BackupPath' does not contain exact Hermes.Desktop restore metadata."
    }

    if (-not $PSCmdlet.ShouldProcess('Windows desktop settings', "Restore from '$BackupPath'")) { return }

    $safetyBackup = $null
    if ($CreateSafetyBackup) {
        $parameters = @{}
        if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $parameters.BackupDirectory = $BackupDirectory }
        $safetyBackup = Backup-HermesDesktopSettings @parameters
    }

    $targets = @{
        WallPaper = @{ Path = $script:DesktopPath; Name = 'WallPaper'; Type = 'String' }
        WallpaperStyle = @{ Path = $script:DesktopPath; Name = 'WallpaperStyle'; Type = 'String' }
        TileWallpaper = @{ Path = $script:DesktopPath; Name = 'TileWallpaper'; Type = 'String' }
        HideIcons = @{ Path = $script:ExplorerAdvancedPath; Name = 'HideIcons'; Type = 'DWord' }
    }

    foreach ($name in $targets.Keys) {
        $saved = $document.AdditionalMetadata.Registry.$name
        $target = $targets[$name]
        if ([bool]$saved.Exists) {
            Set-HermesRegistryValue -Path $target.Path -Name $target.Name -Value $saved.Value -Type $target.Type -CreatePath -Confirm:$false | Out-Null
        }
        else {
            Remove-HermesRegistryValue -Path $target.Path -Name $target.Name -IgnoreMissing -Confirm:$false | Out-Null
        }
    }

    Invoke-HermesDesktopRefresh
    $explorerRestarted = $false
    if ($RestartExplorer) { Restart-HermesExplorer -Confirm:$false | Out-Null; $explorerRestarted = $true }

    $after = Get-HermesDesktopSettings
    [pscustomobject]@{
        Changed = $true
        SourceBackupPath = $BackupPath
        SafetyBackup = $safetyBackup
        After = $after
        ExplorerRestarted = $explorerRestarted
    }
}

Export-ModuleMember -Function @(
    'Get-HermesDesktopSettings'
    'Test-HermesDesktopConfiguration'
    'Test-HermesDesktopSettings'
    'Backup-HermesDesktopSettings'
    'Set-HermesDesktopSettings'
    'Restore-HermesDesktopSettings'
)
