Set-StrictMode -Version Latest

$script:ModuleName='Hermes.VSCode'
$script:SupportedSettings=@(
    'workbench.colorTheme','editor.fontFamily','editor.fontSize','editor.formatOnSave',
    'files.autoSave','terminal.integrated.defaultProfile.windows','git.autofetch',
    'telemetry.telemetryLevel','security.workspace.trust.enabled'
)
$coreManifest=Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
if(-not(Test-Path -LiteralPath $coreManifest -PathType Leaf)){throw "Hermes.Core could not be found at '$coreManifest'."}
Import-Module $coreManifest -Force -ErrorAction Stop

function Get-HermesVSCodeSettingsPath {
    param([string]$SettingsPath)
    if(-not[string]::IsNullOrWhiteSpace($SettingsPath)){return [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($SettingsPath))}
    $candidates=@(
        (Join-Path $env:APPDATA 'Code\User\settings.json'),
        (Join-Path $env:APPDATA 'Code - Insiders\User\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\data\user-data\User\settings.json')
    )
    $existing=@($candidates|Where-Object{Test-Path -LiteralPath $_ -PathType Leaf})
    if($existing.Count){return [IO.Path]::GetFullPath($existing[0])}
    [IO.Path]::GetFullPath($candidates[0])
}

function ConvertFrom-HermesJsonC {
    param([AllowEmptyString()][string]$Text,[string]$Path)
    if([string]::IsNullOrWhiteSpace($Text)){return [ordered]@{}}
    $builder=[Text.StringBuilder]::new();$inString=$false;$escaped=$false;$lineComment=$false;$blockComment=$false
    for($i=0;$i-lt$Text.Length;$i++){
        $c=$Text[$i];$next=if($i+1-lt$Text.Length){$Text[$i+1]}else{[char]0}
        if($lineComment){if($c-eq"`n"){$lineComment=$false;[void]$builder.Append($c)};continue}
        if($blockComment){if($c-eq'*'-and$next-eq'/'){$blockComment=$false;$i++};continue}
        if($inString){[void]$builder.Append($c);if($escaped){$escaped=$false}elseif($c-eq'\'){$escaped=$true}elseif($c-eq'"'){$inString=$false};continue}
        if($c-eq'"'){$inString=$true;[void]$builder.Append($c);continue}
        if($c-eq'/'-and$next-eq'/'){$lineComment=$true;$i++;continue}
        if($c-eq'/'-and$next-eq'*'){$blockComment=$true;$i++;continue}
        [void]$builder.Append($c)
    }
    $json=[regex]::Replace($builder.ToString(),',\s*([}\]])','$1')
    try{$value=$json|ConvertFrom-Json -AsHashtable -Depth 100 -ErrorAction Stop;if($value-isnot[Collections.IDictionary]){throw 'Root value must be an object.'};$value}
    catch{throw "VS Code settings at '$Path' are not valid JSONC. $($_.Exception.Message)"}
}

function Read-HermesVSCodeDocument {
    param([string]$Path)
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return [ordered]@{}}
    $text=Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if($null-eq$text){$text=''}
    ConvertFrom-HermesJsonC -Text $text -Path $Path
}

function Test-HermesVSCodeConfiguration {
    <#.SYNOPSIS Validates and normalizes a Project Hermes VS Code configuration.
      .PARAMETER Configuration Desired VS Code Settings hashtable.#>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)
    $errors=[Collections.Generic.List[string]]::new();$properties=@(if($Configuration-is[Collections.IDictionary]){$Configuration.Keys}else{$Configuration.PSObject.Properties.Name})
    if($properties.Count-ne1-or'Settings'-notin$properties){$errors.Add('Configuration must contain only a non-empty Settings hashtable.')}
    $settings=if($Configuration-is[Collections.IDictionary]){$Configuration['Settings']}else{$Configuration.Settings}
    $normalized=[ordered]@{}
    if($settings-isnot[Collections.IDictionary]){$errors.Add('Settings must be a hashtable.')}else{
        foreach($key in $settings.Keys){if($key-notin$script:SupportedSettings){$errors.Add("Unsupported VS Code setting '$key'.")}else{$normalized[[string]$key]=$settings[$key]}}
        if($settings.Count-eq0){$errors.Add('Settings cannot be empty.')}
    }
    if($normalized.Contains('editor.fontSize')-and($normalized['editor.fontSize']-isnot[int]-or$normalized['editor.fontSize']-lt8-or$normalized['editor.fontSize']-gt72)){$errors.Add('editor.fontSize must be an integer from 8 through 72.')}
    foreach($key in @('editor.formatOnSave','git.autofetch','security.workspace.trust.enabled')){if($normalized.Contains($key)-and$normalized[$key]-isnot[bool]){$errors.Add("$key must be Boolean.")}}
    foreach($key in @('workbench.colorTheme','editor.fontFamily','files.autoSave','terminal.integrated.defaultProfile.windows','telemetry.telemetryLevel')){if($normalized.Contains($key)-and[string]::IsNullOrWhiteSpace([string]$normalized[$key])){$errors.Add("$key cannot be empty.")}}
    [pscustomobject]@{IsValid=($errors.Count-eq0);Errors=@($errors);Configuration=[ordered]@{Settings=$normalized}}
}

function Get-HermesVSCodeSettings {
    <#.SYNOPSIS Reads the selected VS Code user settings managed by Project Hermes.
      .PARAMETER SettingsPath Optional settings.json path.#>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath)
    $path=Get-HermesVSCodeSettingsPath $SettingsPath;$document=Read-HermesVSCodeDocument $path;$managed=[ordered]@{}
    foreach($key in $script:SupportedSettings){$managed[$key]=if($document.Contains($key)){$document[$key]}else{'NotConfigured'}}
    [pscustomobject]@{SettingsPath=$path;SettingsExist=Test-Path -LiteralPath $path -PathType Leaf;Settings=[pscustomobject]$managed}
}

function Test-HermesVSCodeSettings {
    <#.SYNOPSIS Compares current VS Code user settings with desired Hermes state.
      .PARAMETER Configuration Desired VS Code configuration.
      .PARAMETER SettingsPath Optional settings.json path.#>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath)
    $validation=Test-HermesVSCodeConfiguration $Configuration;if(-not$validation.IsValid){throw($validation.Errors-join' ')}
    $current=Get-HermesVSCodeSettings $SettingsPath;$differences=[Collections.Generic.List[object]]::new()
    foreach($key in $validation.Configuration.Settings.Keys){$actual=$current.Settings.$key;$expected=$validation.Configuration.Settings[$key];if(($actual|ConvertTo-Json -Compress)-cne($expected|ConvertTo-Json -Compress)){$differences.Add([pscustomobject]@{Setting=$key;Expected=$expected;Actual=$actual})}}
    [pscustomobject]@{IsCompliant=($differences.Count-eq0);Current=$current;Desired=$validation.Configuration;Differences=@($differences)}
}

$script:ModuleName = 'Hermes.VSCode'

function Backup-HermesVSCodeSettings {
    <#.SYNOPSIS Backs up the exact VS Code user settings file before modification.#>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$SettingsPath,[string]$BackupDirectory)
    $path=Get-HermesVSCodeSettingsPath $SettingsPath;$exists=Test-Path -LiteralPath $path -PathType Leaf;$bytes=[byte[]]::new(0);if($exists){$bytes=[IO.File]::ReadAllBytes($path)}
    $p=@{ModuleName=$script:ModuleName;Settings=[pscustomobject]@{SettingsPath=$path;Existed=$exists;ContentBase64=[Convert]::ToBase64String($bytes)}};if($PSBoundParameters.ContainsKey('BackupDirectory')){$p.BackupDirectory=$BackupDirectory};Write-HermesBackup @p
}

function Set-HermesVSCodeSettings {
    <#.SYNOPSIS Applies selected Hermes VS Code settings while preserving unrelated values.
      .PARAMETER Configuration Desired configuration.
      .PARAMETER SettingsPath Optional settings.json path.
      .PARAMETER BackupDirectory Optional backup destination.
      .PARAMETER SkipBackup Suppresses automatic backup.#>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$SettingsPath,[string]$BackupDirectory,[switch]$SkipBackup)
    $v=Test-HermesVSCodeConfiguration $Configuration;if(-not$v.IsValid){throw($v.Errors-join' ')};$path=Get-HermesVSCodeSettingsPath $SettingsPath;$pre=Test-HermesVSCodeSettings $v.Configuration $path
    if($pre.IsCompliant){return [pscustomobject]@{Changed=$false;Backup=$null;SettingsPath=$path;Verification=$pre}}
    if(-not$PSCmdlet.ShouldProcess($path,'Apply Project Hermes VS Code user settings')){return}
    $backup=$null;if(-not$SkipBackup){$bp=@{SettingsPath=$path};if($PSBoundParameters.ContainsKey('BackupDirectory')){$bp.BackupDirectory=$BackupDirectory};$backup=Backup-HermesVSCodeSettings @bp}
    $document=Read-HermesVSCodeDocument $path;foreach($key in $v.Configuration.Settings.Keys){$document[$key]=$v.Configuration.Settings[$key]}
    try{$directory=Split-Path -Parent $path;if(-not(Test-Path $directory -PathType Container)){New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop|Out-Null};$document|ConvertTo-Json -Depth 100|Set-Content -LiteralPath $path -Encoding utf8NoBOM -Force -ErrorAction Stop}catch{throw "Unable to update VS Code settings '$path'. $($_.Exception.Message)"}
    $verification=Test-HermesVSCodeSettings $v.Configuration $path;if(-not$verification.IsCompliant){throw'Hermes VS Code post-change verification failed.'};[pscustomobject]@{Changed=$true;Backup=$backup;SettingsPath=$path;Verification=$verification}
}

function Restore-HermesVSCodeSettings {
    <#.SYNOPSIS Restores the exact VS Code settings file from a Hermes backup.
      .PARAMETER BackupPath Hermes.VSCode backup path.
      .PARAMETER CreateSafetyBackup Creates a pre-restore backup.#>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$BackupPath,[switch]$CreateSafetyBackup)
    $doc=Read-HermesBackup -BackupPath $BackupPath -ExpectedModuleName $script:ModuleName;$path=[string]$doc.Settings.SettingsPath;if([string]::IsNullOrWhiteSpace($path)){throw'Backup contains no VS Code settings path.'};if(-not$PSCmdlet.ShouldProcess($path,"Restore from '$BackupPath'")){return};$safety=if($CreateSafetyBackup){Backup-HermesVSCodeSettings $path}else{$null}
    if([bool]$doc.Settings.Existed){$bytes=[Convert]::FromBase64String([string]$doc.Settings.ContentBase64);$directory=Split-Path -Parent $path;if(-not(Test-Path $directory)){New-Item -ItemType Directory -Path $directory -Force|Out-Null};[IO.File]::WriteAllBytes($path,$bytes)}else{Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
    [pscustomobject]@{Changed=$true;SourceBackupPath=$BackupPath;SafetyBackup=$safety;SettingsPath=$path}
}

Export-ModuleMember -Function @('Get-HermesVSCodeSettings','Test-HermesVSCodeConfiguration','Test-HermesVSCodeSettings','Backup-HermesVSCodeSettings','Set-HermesVSCodeSettings','Restore-HermesVSCodeSettings')

