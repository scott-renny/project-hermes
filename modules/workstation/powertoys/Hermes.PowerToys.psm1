Set-StrictMode -Version Latest

$script:ModuleName='Hermes.PowerToys'
$coreManifest=Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
if(-not(Test-Path $coreManifest -PathType Leaf)){throw "Hermes.Core could not be found at '$coreManifest'."}
Import-Module $coreManifest -Force -ErrorAction Stop

$script:GlobalMap=[ordered]@{
    Startup='startup'
    Theme='theme'
    RunElevated='run_elevated'
    EnableExperimentation='enable_experimentation'
    ShowWhatsNewAfterUpdate='show_whats_new_after_updates'
}
$script:FeatureMap=[ordered]@{
    AlwaysOnTop='AlwaysOnTop'
    Awake='Awake'
    CmdPal='CmdPal'
    ColorPicker='ColorPicker'
    FancyZones='FancyZones'
    FileExplorer='File Explorer'
    FileLocksmith='File Locksmith'
    FindMyMouse='FindMyMouse'
    ImageResizer='Image Resizer'
    MeasureTool='Measure Tool'
    MouseHighlighter='MouseHighlighter'
    Peek='Peek'
    PowerRename='PowerRename'
    PowerToysRun='PowerToys Run'
    ShortcutGuide='Shortcut Guide'
    TextExtractor='TextExtractor'
}

function Get-HermesPowerToysSettingsPath{
    param([string]$SettingsPath)
    if(-not[string]::IsNullOrWhiteSpace($SettingsPath)){return [IO.Path]::GetFullPath($SettingsPath)}
    Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
}

function Read-HermesPowerToysDocument{
    param([Parameter(Mandatory)][string]$Path)
    if(-not(Test-Path $Path -PathType Leaf)){return[ordered]@{}}
    try{
        $content=Get-Content $Path -Raw -Encoding utf8 -ErrorAction Stop
        if([string]::IsNullOrWhiteSpace($content)){return[ordered]@{}}
        $content|ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }catch{throw "Unable to read PowerToys settings '$Path'. $($_.Exception.Message)"}
}

function Write-HermesPowerToysDocument{
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][hashtable]$Document)
    try{
        $directory=Split-Path $Path -Parent
        if(-not(Test-Path $directory -PathType Container)){New-Item -ItemType Directory $directory -Force -ErrorAction Stop|Out-Null}
        $json=$Document|ConvertTo-Json -Depth 20
        [IO.File]::WriteAllText($Path,$json,[Text.UTF8Encoding]::new($false))
    }catch{throw "Unable to write PowerToys settings '$Path'. $($_.Exception.Message)"}
}

function Get-HermesPowerToysSettings{
    <#
    .SYNOPSIS Gets the current PowerToys settings managed by Project Hermes.
    .PARAMETER SettingsPath Optional path to a PowerToys settings.json file.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath)
    $path=Get-HermesPowerToysSettingsPath $SettingsPath
    $exists=Test-Path $path -PathType Leaf
    $document=Read-HermesPowerToysDocument $path
    $globals=[ordered]@{};$features=[ordered]@{}
    foreach($name in $script:GlobalMap.Keys){
        $native=$script:GlobalMap[$name]
        $globals[$name]=if($document.ContainsKey($native)){$document[$native]}else{'NotConfigured'}
    }
    $enabled=if($document.ContainsKey('enabled')-and $document.enabled-is[Collections.IDictionary]){$document.enabled}else{@{}}
    foreach($name in $script:FeatureMap.Keys){
        $native=$script:FeatureMap[$name]
        $features[$name]=if($enabled.ContainsKey($native)){$enabled[$native]}else{'NotConfigured'}
    }
    [pscustomobject]@{
        SettingsPath=$path
        SettingsExist=$exists
        Version=if($document.ContainsKey('powertoys_version')){$document.powertoys_version}else{'NotConfigured'}
        GlobalSettings=[pscustomobject]$globals
        Features=[pscustomobject]$features
    }
}

function Test-HermesPowerToysConfiguration{
    <#
    .SYNOPSIS Validates and normalizes a Hermes PowerToys configuration.
    .PARAMETER Configuration Configuration containing GlobalSettings and/or Features.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration)
    $errors=[Collections.Generic.List[string]]::new();$normalized=[ordered]@{}
    $properties=@(if($Configuration-is[Collections.IDictionary]){$Configuration.Keys}else{$Configuration.PSObject.Properties.Name})
    if($properties.Count-eq 0){$errors.Add('Configuration cannot be empty.')}
    foreach($property in $properties){if($property-notin@('GlobalSettings','Features')){$errors.Add("Unsupported top-level setting '$property'.")}}
    foreach($sectionName in @('GlobalSettings','Features')){
        if($sectionName-notin$properties){continue}
        $section=if($Configuration-is[Collections.IDictionary]){$Configuration[$sectionName]}else{$Configuration.$sectionName}
        if($section-isnot[Collections.IDictionary]-or$section.Count-eq 0){$errors.Add("$sectionName must be a non-empty hashtable.");continue}
        $allowed=if($sectionName-eq'GlobalSettings'){$script:GlobalMap}else{$script:FeatureMap}
        $output=[ordered]@{}
        foreach($name in $section.Keys){
            if(-not$allowed.Contains($name)){$errors.Add("Unsupported $sectionName setting '$name'.");continue}
            $value=$section[$name]
            if($sectionName-eq'GlobalSettings'-and$name-eq'Theme'){
                if(([string]$value).ToLowerInvariant()-notin@('dark','light','system')){$errors.Add('Theme must be dark, light, or system.')}
                else{$output[$name]=([string]$value).ToLowerInvariant()}
            }elseif($value-isnot[bool]){$errors.Add("$sectionName setting '$name' must be Boolean.")}
            else{$output[$name]=[bool]$value}
        }
        $normalized[$sectionName]=$output
    }
    [pscustomobject]@{IsValid=$errors.Count-eq 0;Errors=@($errors);Configuration=$normalized}
}

function Test-HermesPowerToysSettings{
    <#
    .SYNOPSIS Compares current PowerToys settings with a desired configuration.
    .PARAMETER Configuration Desired Hermes PowerToys configuration.
    .PARAMETER SettingsPath Optional path to a PowerToys settings.json file.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath)
    $validation=Test-HermesPowerToysConfiguration $Configuration
    if(-not$validation.IsValid){throw($validation.Errors-join[Environment]::NewLine)}
    $current=Get-HermesPowerToysSettings $SettingsPath
    $differences=[Collections.Generic.List[object]]::new()
    foreach($section in $validation.Configuration.Keys){
        foreach($name in $validation.Configuration[$section].Keys){
            $actual=$current.$section.$name;$expected=$validation.Configuration[$section][$name]
            if($actual-ne$expected){$differences.Add([pscustomobject]@{Section=$section;Setting=$name;Expected=$expected;Actual=$actual})}
        }
    }
    [pscustomobject]@{IsCompliant=$differences.Count-eq 0;Current=$current;Desired=$validation.Configuration;Differences=@($differences)}
}

function Backup-HermesPowerToysSettings{
    <#
    .SYNOPSIS Backs up the exact PowerToys settings file.
    .PARAMETER SettingsPath Optional settings.json path.
    .PARAMETER BackupDirectory Optional backup destination.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath,[string]$BackupDirectory)
    $path=Get-HermesPowerToysSettingsPath $SettingsPath;$exists=Test-Path $path -PathType Leaf
    $bytes=[byte[]]::new(0);if($exists){$bytes=[IO.File]::ReadAllBytes($path)}
    $parameters=@{ModuleName=$script:ModuleName;Settings=[pscustomobject]@{SettingsPath=$path;Existed=$exists;ContentBase64=[Convert]::ToBase64String($bytes)}}
    if($PSBoundParameters.ContainsKey('BackupDirectory')){$parameters.BackupDirectory=$BackupDirectory}
    Write-HermesBackup @parameters
}

function Set-HermesPowerToysSettings{
    <#
    .SYNOPSIS Applies selected Hermes PowerToys settings while preserving unmanaged values.
    .PARAMETER Configuration Desired configuration.
    .PARAMETER SettingsPath Optional settings.json path.
    .PARAMETER BackupDirectory Optional backup destination.
    .PARAMETER SkipBackup Suppresses automatic backup.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath,[string]$BackupDirectory,[switch]$SkipBackup)
    $validation=Test-HermesPowerToysConfiguration $Configuration
    if(-not$validation.IsValid){throw($validation.Errors-join[Environment]::NewLine)}
    $path=Get-HermesPowerToysSettingsPath $SettingsPath
    $before=Test-HermesPowerToysSettings $validation.Configuration $path
    if($before.IsCompliant){return [pscustomobject]@{Changed=$false;Backup=$null;SettingsPath=$path;Verification=$before}}
    if(-not$PSCmdlet.ShouldProcess($path,'Apply Project Hermes PowerToys configuration')){return}
    $backup=$null
    if(-not$SkipBackup){
        $bp=@{SettingsPath=$path};if($PSBoundParameters.ContainsKey('BackupDirectory')){$bp.BackupDirectory=$BackupDirectory}
        $backup=Backup-HermesPowerToysSettings @bp
    }
    $document=Read-HermesPowerToysDocument $path
    if(-not$document.ContainsKey('enabled')-or$document.enabled-isnot[Collections.IDictionary]){$document.enabled=[ordered]@{}}
    if($validation.Configuration.Contains('GlobalSettings')){
        foreach($name in $validation.Configuration.GlobalSettings.Keys){$document[$script:GlobalMap[$name]]=$validation.Configuration.GlobalSettings[$name]}
    }
    if($validation.Configuration.Contains('Features')){
        foreach($name in $validation.Configuration.Features.Keys){$document.enabled[$script:FeatureMap[$name]]=$validation.Configuration.Features[$name]}
    }
    Write-HermesPowerToysDocument $path $document
    $verification=Test-HermesPowerToysSettings $validation.Configuration $path
    if(-not$verification.IsCompliant){throw 'Hermes PowerToys post-change verification failed.'}
    [pscustomobject]@{Changed=$true;Backup=$backup;SettingsPath=$path;Verification=$verification}
}

function Restore-HermesPowerToysSettings{
    <#
    .SYNOPSIS Restores an exact PowerToys settings backup.
    .PARAMETER BackupPath Path to a Hermes.PowerToys backup.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$BackupPath)
    $backup=Read-HermesBackup $BackupPath -ExpectedModuleName $script:ModuleName
    if($null-eq$backup.Settings-or[string]::IsNullOrWhiteSpace([string]$backup.Settings.SettingsPath)){throw 'The backup does not contain exact PowerToys restore metadata.'}
    $path=[string]$backup.Settings.SettingsPath
    if(-not$PSCmdlet.ShouldProcess($path,"Restore PowerToys settings from '$BackupPath'")){return}
    if([bool]$backup.Settings.Existed){
        $bytes=[Convert]::FromBase64String([string]$backup.Settings.ContentBase64);$directory=Split-Path $path -Parent
        if(-not(Test-Path $directory -PathType Container)){New-Item -ItemType Directory $directory -Force|Out-Null}
        [IO.File]::WriteAllBytes($path,$bytes)
    }elseif(Test-Path $path -PathType Leaf){Remove-Item $path -Force -ErrorAction Stop}
    [pscustomobject]@{Restored=$true;SettingsPath=$path;BackupPath=[IO.Path]::GetFullPath($BackupPath)}
}

Export-ModuleMember -Function @(
    'Get-HermesPowerToysSettings'
    'Test-HermesPowerToysConfiguration'
    'Test-HermesPowerToysSettings'
    'Backup-HermesPowerToysSettings'
    'Set-HermesPowerToysSettings'
    'Restore-HermesPowerToysSettings'
)
