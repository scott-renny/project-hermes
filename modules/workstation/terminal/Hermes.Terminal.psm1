Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.Terminal'
$script:SupportedSettings = @('Theme','ColorScheme','FontFace','FontSize','Opacity','UseAcrylic','CursorShape')
$script:RequiredSchemeColors = @(
    'Name','Foreground','Background','CursorColor','SelectionBackground',
    'Black','Red','Green','Yellow','Blue','Purple','Cyan','White',
    'BrightBlack','BrightRed','BrightGreen','BrightYellow','BrightBlue',
    'BrightPurple','BrightCyan','BrightWhite'
)

$coreManifest = Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Hermes.Core could not be found at '$coreManifest'."
}
Import-Module $coreManifest -Force -ErrorAction Stop

function Get-HermesTerminalSettingsPath {
    [CmdletBinding()][OutputType([string])]
    param([string]$SettingsPath)

    if (-not [string]::IsNullOrWhiteSpace($SettingsPath)) {
        return [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($SettingsPath))
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
    $existing = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    if ($existing.Count -gt 0) { return [IO.Path]::GetFullPath($existing[0]) }
    [IO.Path]::GetFullPath($candidates[0])
}

function Read-HermesTerminalDocument {
    [CmdletBinding()][OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @{} }
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($text)) { return @{} }
    try { $text | ConvertFrom-Json -AsHashtable -Depth 100 -ErrorAction Stop }
    catch { throw "Windows Terminal settings at '$Path' are not valid JSON. $($_.Exception.Message)" }
}

function Get-HermesDictionaryValue {
    param([object]$Dictionary,[string]$Name,$Default=$null)
    if ($Dictionary -is [Collections.IDictionary]) {
        $matchingKey = @($Dictionary.Keys | Where-Object { [string]$_ -ieq $Name } | Select-Object -First 1)
        if ($matchingKey.Count -gt 0) { return $Dictionary[$matchingKey[0]] }
    }
    $Default
}

function Test-HermesHexColor {
    param([string]$Value)
    -not [string]::IsNullOrWhiteSpace($Value) -and $Value -match '^#[0-9A-Fa-f]{6}$'
}

function Test-HermesTerminalConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes a Project Hermes Windows Terminal configuration.
    .PARAMETER Configuration
        Desired Terminal defaults and complete color-scheme definition.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $keys = @(if ($Configuration -is [Collections.IDictionary]) { $Configuration.Keys } else { $Configuration.PSObject.Properties.Name })
    foreach ($key in $keys | Where-Object { $_ -notin @($script:SupportedSettings + 'Scheme') }) {
        $errors.Add("Unsupported Terminal setting '$key'.")
    }
    if ($keys.Count -eq 0) { $errors.Add('Terminal configuration cannot be empty.') }

    $value = { param($name,$default=$null) if ($Configuration -is [Collections.IDictionary]) { if ($Configuration.Contains($name)){$Configuration[$name]}else{$default} } else { if($Configuration.PSObject.Properties.Name -contains $name){$Configuration.$name}else{$default} } }
    $normalized = [ordered]@{}

    $theme = [string](& $value 'Theme' 'dark')
    if ($theme.ToLowerInvariant() -notin @('dark','light','system')) { $errors.Add("Theme must be Dark, Light, or System.") }
    else { $normalized.Theme = $theme.ToLowerInvariant() }

    $schemeName = [string](& $value 'ColorScheme' '')
    if ([string]::IsNullOrWhiteSpace($schemeName)) { $errors.Add('ColorScheme is required.') }
    else { $normalized.ColorScheme = $schemeName.Trim() }

    $fontFace = [string](& $value 'FontFace' '')
    if ([string]::IsNullOrWhiteSpace($fontFace)) { $errors.Add('FontFace is required.') }
    else { $normalized.FontFace = $fontFace.Trim() }

    $fontSize = & $value 'FontSize' 0
    if ($fontSize -isnot [int] -or $fontSize -lt 8 -or $fontSize -gt 72) { $errors.Add('FontSize must be an integer from 8 through 72.') }
    else { $normalized.FontSize = $fontSize }

    $opacity = & $value 'Opacity' -1
    if ($opacity -isnot [int] -or $opacity -lt 0 -or $opacity -gt 100) { $errors.Add('Opacity must be an integer from 0 through 100.') }
    else { $normalized.Opacity = $opacity }

    $acrylic = & $value 'UseAcrylic' $null
    if ($acrylic -isnot [bool]) { $errors.Add('UseAcrylic must be Boolean.') }
    else { $normalized.UseAcrylic = $acrylic }

    $cursor = [string](& $value 'CursorShape' '')
    $allowedCursors = @('bar','vintage','underscore','filledBox','emptyBox','doubleUnderscore')
    $canonicalCursor = $allowedCursors | Where-Object { $_ -ieq $cursor } | Select-Object -First 1
    if (-not $canonicalCursor) { $errors.Add("CursorShape must be one of: $($allowedCursors -join ', ').") }
    else { $normalized.CursorShape = $canonicalCursor }

    $scheme = & $value 'Scheme' $null
    if ($scheme -isnot [Collections.IDictionary]) { $errors.Add('Scheme must be a PowerShell data-file hashtable.') }
    else {
        $normalizedScheme = [ordered]@{}
        foreach ($name in $script:RequiredSchemeColors) {
            $matchingKey = @($scheme.Keys | Where-Object { [string]$_ -ieq $name } | Select-Object -First 1)
            if ($matchingKey.Count -eq 0) { $errors.Add("Scheme is missing '$name'."); continue }
            $color = [string]$scheme[$matchingKey[0]]
            if ($name -ne 'Name' -and -not (Test-HermesHexColor $color)) { $errors.Add("Scheme color '$name' must use #RRGGBB format.") }
            $jsonName = $name.Substring(0,1).ToLowerInvariant() + $name.Substring(1)
            $normalizedScheme[$jsonName] = $color
        }
        $schemeName = Get-HermesDictionaryValue $scheme 'Name' ''
        if (-not [string]::IsNullOrWhiteSpace([string]$schemeName) -and $normalized.Contains('ColorScheme') -and [string]$schemeName -ne $normalized.ColorScheme) {
            $errors.Add('Scheme.Name must match ColorScheme.')
        }
        $normalized.Scheme = $normalizedScheme
    }

    [pscustomobject]@{ IsValid=($errors.Count -eq 0); Errors=@($errors); Configuration=$normalized }
}

function Get-HermesTerminalSettings {
    <#
    .SYNOPSIS
        Reads the Windows Terminal settings managed by Project Hermes.
    .PARAMETER SettingsPath
        Optional settings.json path; otherwise the installed Terminal location is discovered.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath)

    $path = Get-HermesTerminalSettingsPath -SettingsPath $SettingsPath
    $document = Read-HermesTerminalDocument -Path $path
    $defaults = Get-HermesDictionaryValue (Get-HermesDictionaryValue $document 'profiles' @{}) 'defaults' @{}
    $font = Get-HermesDictionaryValue $defaults 'font' @{}
    [pscustomobject]@{
        SettingsPath = $path
        SettingsExist = Test-Path -LiteralPath $path -PathType Leaf
        Theme = Get-HermesDictionaryValue $document 'theme' 'NotConfigured'
        ColorScheme = Get-HermesDictionaryValue $defaults 'colorScheme' 'NotConfigured'
        FontFace = Get-HermesDictionaryValue $font 'face' 'NotConfigured'
        FontSize = Get-HermesDictionaryValue $font 'size' 'NotConfigured'
        Opacity = Get-HermesDictionaryValue $defaults 'opacity' 'NotConfigured'
        UseAcrylic = Get-HermesDictionaryValue $defaults 'useAcrylic' 'NotConfigured'
        CursorShape = Get-HermesDictionaryValue $defaults 'cursorShape' 'NotConfigured'
        Schemes = @((Get-HermesDictionaryValue $document 'schemes' @()) | ForEach-Object { Get-HermesDictionaryValue $_ 'name' '' })
    }
}

function Test-HermesTerminalSettings {
    <#
    .SYNOPSIS
        Compares current Windows Terminal settings with desired Hermes state.
    .PARAMETER Configuration
        Desired Terminal configuration.
    .PARAMETER SettingsPath
        Optional settings.json path.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath)

    $validation = Test-HermesTerminalConfiguration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }
    $current = Get-HermesTerminalSettings -SettingsPath $SettingsPath
    $differences = [Collections.Generic.List[object]]::new()
    foreach ($name in $script:SupportedSettings) {
        if ($current.$name -cne $validation.Configuration[$name]) {
            $differences.Add([pscustomobject]@{Setting=$name;Expected=$validation.Configuration[$name];Actual=$current.$name})
        }
    }
    if ($validation.Configuration.ColorScheme -notin $current.Schemes) {
        $differences.Add([pscustomobject]@{Setting='Scheme';Expected=$validation.Configuration.ColorScheme;Actual='Missing'})
    }
    [pscustomobject]@{ IsCompliant=($differences.Count -eq 0); Current=$current; Desired=$validation.Configuration; Differences=@($differences) }
}

function Backup-HermesTerminalSettings {
    <#
    .SYNOPSIS
        Backs up the exact Windows Terminal settings file before modification.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath,[string]$BackupDirectory)

    $path = Get-HermesTerminalSettingsPath -SettingsPath $SettingsPath
    $exists = Test-Path -LiteralPath $path -PathType Leaf
    $bytes = if ($exists) { [IO.File]::ReadAllBytes($path) } else { [byte[]]@() }
    $parameters = @{ ModuleName=$script:ModuleName; Settings=[pscustomobject]@{SettingsPath=$path;Existed=$exists;ContentBase64=[Convert]::ToBase64String($bytes)} }
    if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $parameters.BackupDirectory=$BackupDirectory }
    Write-HermesBackup @parameters
}

function Set-HermesTerminalSettings {
    <#
    .SYNOPSIS
        Applies the Hermes defaults and color scheme while preserving unrelated Terminal settings.
    .PARAMETER Configuration
        Desired Terminal configuration.
    .PARAMETER SettingsPath
        Optional settings.json path.
    .PARAMETER BackupDirectory
        Optional backup destination.
    .PARAMETER SkipBackup
        Suppresses the automatic safety backup.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath,[string]$BackupDirectory,[switch]$SkipBackup)

    $validation = Test-HermesTerminalConfiguration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }
    $path = Get-HermesTerminalSettingsPath -SettingsPath $SettingsPath
    $precheck = Test-HermesTerminalSettings -Configuration $validation.Configuration -SettingsPath $path
    if ($precheck.IsCompliant) { return [pscustomobject]@{Changed=$false;Backup=$null;SettingsPath=$path;Verification=$precheck} }
    if (-not $PSCmdlet.ShouldProcess($path,'Apply Project Hermes Windows Terminal configuration')) { return }

    $backup = $null
    if (-not $SkipBackup) {
        $bp=@{SettingsPath=$path}; if($PSBoundParameters.ContainsKey('BackupDirectory')){$bp.BackupDirectory=$BackupDirectory}
        $backup=Backup-HermesTerminalSettings @bp
    }
    $document = Read-HermesTerminalDocument -Path $path
    if (-not $document.Contains('profiles') -or $document.profiles -isnot [Collections.IDictionary]) { $document.profiles=@{} }
    if (-not $document.profiles.Contains('defaults') -or $document.profiles.defaults -isnot [Collections.IDictionary]) { $document.profiles.defaults=@{} }
    if (-not $document.profiles.defaults.Contains('font') -or $document.profiles.defaults.font -isnot [Collections.IDictionary]) { $document.profiles.defaults.font=@{} }
    $document.theme=$validation.Configuration.Theme
    $document.profiles.defaults.colorScheme=$validation.Configuration.ColorScheme
    $document.profiles.defaults.font.face=$validation.Configuration.FontFace
    $document.profiles.defaults.font.size=$validation.Configuration.FontSize
    $document.profiles.defaults.opacity=$validation.Configuration.Opacity
    $document.profiles.defaults.useAcrylic=$validation.Configuration.UseAcrylic
    $document.profiles.defaults.cursorShape=$validation.Configuration.CursorShape
    $schemes=@(Get-HermesDictionaryValue $document 'schemes' @() | Where-Object { (Get-HermesDictionaryValue $_ 'name' '') -ne $validation.Configuration.ColorScheme })
    $document.schemes=@($schemes + @($validation.Configuration.Scheme))

    try {
        $directory=Split-Path -Parent $path
        if(-not(Test-Path -LiteralPath $directory -PathType Container)){New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop|Out-Null}
        $json=$document|ConvertTo-Json -Depth 100
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM -Force -ErrorAction Stop
    } catch { throw "Unable to update Windows Terminal settings '$path'. $($_.Exception.Message)" }
    $verification=Test-HermesTerminalSettings -Configuration $validation.Configuration -SettingsPath $path
    if(-not $verification.IsCompliant){throw 'Hermes Terminal post-change verification failed.'}
    [pscustomobject]@{Changed=$true;Backup=$backup;SettingsPath=$path;Verification=$verification}
}

function Restore-HermesTerminalSettings {
    <#
    .SYNOPSIS
        Restores the exact Windows Terminal settings file from a Hermes backup.
    .PARAMETER BackupPath
        Hermes.Terminal backup JSON path.
    .PARAMETER CreateSafetyBackup
        Creates another backup before restoration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$BackupPath,[switch]$CreateSafetyBackup)

    $document=Read-HermesBackup -BackupPath $BackupPath -ExpectedModuleName $script:ModuleName
    $path=[string]$document.Settings.SettingsPath
    if([string]::IsNullOrWhiteSpace($path)){throw 'Backup does not contain a Windows Terminal settings path.'}
    if(-not $PSCmdlet.ShouldProcess($path,"Restore from '$BackupPath'")){return}
    $safety=if($CreateSafetyBackup){Backup-HermesTerminalSettings -SettingsPath $path}else{$null}
    if([bool]$document.Settings.Existed){
        $bytes=[Convert]::FromBase64String([string]$document.Settings.ContentBase64)
        $directory=Split-Path -Parent $path
        if(-not(Test-Path -LiteralPath $directory -PathType Container)){New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop|Out-Null}
        [IO.File]::WriteAllBytes($path,$bytes)
    } else { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    [pscustomobject]@{Changed=$true;SourceBackupPath=$BackupPath;SafetyBackup=$safety;SettingsPath=$path}
}

Export-ModuleMember -Function @(
    'Get-HermesTerminalSettings','Test-HermesTerminalConfiguration','Test-HermesTerminalSettings',
    'Backup-HermesTerminalSettings','Set-HermesTerminalSettings','Restore-HermesTerminalSettings'
)
