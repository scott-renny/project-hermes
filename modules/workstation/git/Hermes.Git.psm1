Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.Git'
$script:SettingMap = [ordered]@{
    DefaultBranch       = 'init.defaultBranch'
    AutoCrlf            = 'core.autocrlf'
    SafeCrlf            = 'core.safecrlf'
    FetchPrune          = 'fetch.prune'
    PullRebase          = 'pull.rebase'
    PushAutoSetupRemote = 'push.autoSetupRemote'
    CredentialHelper    = 'credential.helper'
}

$coreManifest = Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Hermes.Core could not be found at '$coreManifest'."
}
Import-Module $coreManifest -Force -ErrorAction Stop

function Get-HermesGitExecutable {
    [CmdletBinding()][OutputType([string])]
    param()

    $command = Get-Command git -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $command) {
        throw 'Git could not be found. Install Git for Windows and ensure git.exe is available on PATH.'
    }
    $command.Source
}

function Invoke-HermesGit {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = Get-HermesGitExecutable
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add($argument) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw 'Git process did not start.' }
        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    }
    catch {
        throw "Unable to execute Git. $($_.Exception.Message)"
    }
    finally {
        $process.Dispose()
    }

    if ($exitCode -notin $AllowedExitCodes) {
        $detail = if ([string]::IsNullOrWhiteSpace($standardError)) { $standardOutput.Trim() } else { $standardError.Trim() }
        throw "Git exited with code $exitCode. $detail"
    }
    [pscustomobject]@{
        ExitCode = $exitCode
        Output = $standardOutput.TrimEnd("`r","`n")
        Error = $standardError.TrimEnd("`r","`n")
    }
}

function Get-HermesGitValue {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$Key)

    $result = Invoke-HermesGit -Arguments @('config','--global','--get',$Key) -AllowedExitCodes @(0,1)
    [pscustomobject]@{
        Exists = ($result.ExitCode -eq 0)
        Value = if ($result.ExitCode -eq 0) { $result.Output } else { $null }
    }
}

function ConvertTo-HermesGitBoolean {
    param([object]$Value,[string]$Name,[Collections.Generic.List[string]]$Errors)
    if ($Value -is [bool]) { return $Value.ToString().ToLowerInvariant() }
    $text = [string]$Value
    if ($text -ieq 'true' -or $text -ieq 'false') { return $text.ToLowerInvariant() }
    $Errors.Add("$Name must be Boolean or the string true or false.")
    $null
}

function Test-HermesGitConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes selected Project Hermes global Git defaults.
    .PARAMETER Configuration
        Hashtable or object containing one or more supported Git settings.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $properties = @(if ($Configuration -is [Collections.IDictionary]) { $Configuration.Keys } else { $Configuration.PSObject.Properties.Name })
    foreach ($name in $properties | Where-Object { $_ -notin $script:SettingMap.Keys }) {
        $errors.Add("Unsupported Git setting '$name'.")
    }
    if ($properties.Count -eq 0) { $errors.Add('Git configuration cannot be empty.') }
    $normalized = [ordered]@{}
    $getValue = { param($name) if($Configuration -is [Collections.IDictionary]){$Configuration[$name]}else{$Configuration.$name} }

    foreach ($name in $properties | Where-Object { $_ -in $script:SettingMap.Keys }) {
        $value = & $getValue $name
        switch ($name) {
            'DefaultBranch' {
                $text=[string]$value
                if($text -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$'){$errors.Add('DefaultBranch must be a valid non-empty Git branch name.')}else{$normalized[$name]=$text}
            }
            'AutoCrlf' {
                $text=[string]$value
                if($text.ToLowerInvariant() -notin @('true','false','input')){$errors.Add('AutoCrlf must be true, false, or input.')}else{$normalized[$name]=$text.ToLowerInvariant()}
            }
            'SafeCrlf' {
                $text=[string]$value
                if($text.ToLowerInvariant() -notin @('true','false','warn')){$errors.Add('SafeCrlf must be true, false, or warn.')}else{$normalized[$name]=$text.ToLowerInvariant()}
            }
            { $_ -in @('FetchPrune','PullRebase','PushAutoSetupRemote') } {
                $converted=ConvertTo-HermesGitBoolean -Value $value -Name $name -Errors $errors
                if($null -ne $converted){$normalized[$name]=$converted}
            }
            'CredentialHelper' {
                $text=[string]$value
                if([string]::IsNullOrWhiteSpace($text)){$errors.Add('CredentialHelper cannot be empty.')}else{$normalized[$name]=$text.Trim()}
            }
        }
    }
    [pscustomobject]@{IsValid=($errors.Count -eq 0);Errors=@($errors);Configuration=$normalized}
}

function Get-HermesGitSettings {
    <#
    .SYNOPSIS
        Reads selected user-level Git settings managed by Project Hermes.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param()

    $version = (Invoke-HermesGit -Arguments @('--version')).Output
    $result = [ordered]@{GitExecutable=Get-HermesGitExecutable;GitVersion=$version}
    foreach($entry in $script:SettingMap.GetEnumerator()){
        $current=Get-HermesGitValue -Key $entry.Value
        $result[$entry.Key]=if($current.Exists){$current.Value}else{'NotConfigured'}
    }
    [pscustomobject]$result
}

function Test-HermesGitSettings {
    <#
    .SYNOPSIS
        Compares selected global Git settings with desired Project Hermes state.
    .PARAMETER Configuration
        Desired Git configuration.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration)

    $validation=Test-HermesGitConfiguration $Configuration
    if(-not $validation.IsValid){throw($validation.Errors -join ' ')}
    $current=Get-HermesGitSettings
    $differences=[Collections.Generic.List[object]]::new()
    foreach($name in $validation.Configuration.Keys){
        if([string]$current.$name -cne [string]$validation.Configuration[$name]){
            $differences.Add([pscustomobject]@{Setting=$name;GitKey=$script:SettingMap[$name];Expected=$validation.Configuration[$name];Actual=$current.$name})
        }
    }
    [pscustomobject]@{IsCompliant=($differences.Count -eq 0);Current=$current;Desired=$validation.Configuration;Differences=@($differences)}
}

function Backup-HermesGitSettings {
    <#
    .SYNOPSIS
        Backs up the existence and value of every Git key managed by Hermes.Git.
    .PARAMETER BackupDirectory
        Optional Hermes backup destination.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$BackupDirectory)

    $raw=[ordered]@{}
    foreach($entry in $script:SettingMap.GetEnumerator()){
        $state=Get-HermesGitValue -Key $entry.Value
        $raw[$entry.Key]=[ordered]@{GitKey=$entry.Value;Existed=$state.Exists;Value=$state.Value}
    }
    $parameters=@{ModuleName=$script:ModuleName;Settings=[pscustomobject]@{Values=$raw}}
    if($PSBoundParameters.ContainsKey('BackupDirectory')){$parameters.BackupDirectory=$BackupDirectory}
    Write-HermesBackup @parameters
}

function Set-HermesGitSettings {
    <#
    .SYNOPSIS
        Applies selected Project Hermes Git defaults at global user scope.
    .PARAMETER Configuration
        Desired Git configuration.
    .PARAMETER BackupDirectory
        Optional backup destination.
    .PARAMETER SkipBackup
        Suppresses the automatic safety backup.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string]$BackupDirectory,[switch]$SkipBackup)

    $validation=Test-HermesGitConfiguration $Configuration
    if(-not $validation.IsValid){throw($validation.Errors -join ' ')}
    $precheck=Test-HermesGitSettings $validation.Configuration
    if($precheck.IsCompliant){return [pscustomobject]@{Changed=$false;Backup=$null;Before=$precheck.Current;After=$precheck.Current;Verification=$precheck}}
    if(-not $PSCmdlet.ShouldProcess('global Git configuration','Apply Project Hermes Git defaults')){return}
    $backup=$null
    if(-not $SkipBackup){$bp=@{};if($PSBoundParameters.ContainsKey('BackupDirectory')){$bp.BackupDirectory=$BackupDirectory};$backup=Backup-HermesGitSettings @bp}
    foreach($name in $validation.Configuration.Keys){
        try{Invoke-HermesGit -Arguments @('config','--global',$script:SettingMap[$name],[string]$validation.Configuration[$name])|Out-Null}
        catch{throw "Unable to set Git key '$($script:SettingMap[$name])'. $($_.Exception.Message)"}
    }
    $verification=Test-HermesGitSettings $validation.Configuration
    if(-not $verification.IsCompliant){throw 'Hermes Git post-change verification failed.'}
    [pscustomobject]@{Changed=$true;Backup=$backup;Before=$precheck.Current;After=$verification.Current;Verification=$verification}
}

function Restore-HermesGitSettings {
    <#
    .SYNOPSIS
        Restores the exact managed global Git values from a Hermes.Git backup.
    .PARAMETER BackupPath
        Path to a Hermes.Git backup.
    .PARAMETER CreateSafetyBackup
        Creates a new backup before restoration.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$BackupPath,[switch]$CreateSafetyBackup)

    $document=Read-HermesBackup -BackupPath $BackupPath -ExpectedModuleName $script:ModuleName
    if($null -eq $document.Settings.Values){throw 'Backup contains no restorable Git values.'}
    if(-not $PSCmdlet.ShouldProcess('global Git configuration',"Restore from '$BackupPath'")){return}
    $safety=if($CreateSafetyBackup){Backup-HermesGitSettings}else{$null}
    foreach($property in $document.Settings.Values.PSObject.Properties){
        $state=$property.Value
        if([string]::IsNullOrWhiteSpace([string]$state.GitKey)){throw "Backup value '$($property.Name)' has no Git key."}
        if([bool]$state.Existed){Invoke-HermesGit -Arguments @('config','--global',[string]$state.GitKey,[string]$state.Value)|Out-Null}
        else{Invoke-HermesGit -Arguments @('config','--global','--unset-all',[string]$state.GitKey) -AllowedExitCodes @(0,1,5)|Out-Null}
    }
    [pscustomobject]@{Changed=$true;SourceBackupPath=$BackupPath;SafetyBackup=$safety;Current=Get-HermesGitSettings}
}

Export-ModuleMember -Function @(
    'Get-HermesGitSettings','Test-HermesGitConfiguration','Test-HermesGitSettings',
    'Backup-HermesGitSettings','Set-HermesGitSettings','Restore-HermesGitSettings'
)
