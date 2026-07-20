Set-StrictMode -Version Latest

function Get-HermesWingetExecutable {
    $command=Get-Command winget -ErrorAction SilentlyContinue
    if($null-eq$command){throw 'WinGet is not installed or is unavailable in PATH.'}
    $command.Source
}

function Invoke-HermesWinget {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $executable=Get-HermesWingetExecutable
    $output=@(
        & $executable @Arguments 2>&1 |
            ForEach-Object { [string]$_ }
    )
    [pscustomobject]@{ExitCode=$LASTEXITCODE;Output=$output;Text=$output-join[Environment]::NewLine}
}

function ConvertTo-HermesWingetPackageList {
    param([Parameter(Mandatory)][object]$Configuration,[string[]]$ProfileName)
    $validation=Test-HermesWingetConfiguration $Configuration
    if(-not$validation.IsValid){throw($validation.Errors-join[Environment]::NewLine)}
    $selected=if($PSBoundParameters.ContainsKey('ProfileName') -and @($ProfileName).Count -gt 0){@($ProfileName)}else{@($validation.Configuration.Profiles.Keys)}
    $packages=[Collections.Generic.List[object]]::new()
    foreach($profileName in $selected){
        $profileKey=[string]$profileName
        if(@($validation.Configuration.Profiles.Keys) -inotcontains $profileKey){throw "Unknown package profile '$profileKey'."}
        foreach($package in $validation.Configuration.Profiles[$profileKey]){
            $packages.Add([pscustomobject]@{Profile=$profileKey;Id=$package.Id;Source=$package.Source})
        }
    }
    @($packages)
}

function Test-HermesWingetConfiguration {
    <#
    .SYNOPSIS Validates and normalizes Hermes WinGet package profiles.
    .PARAMETER Configuration Configuration containing a Profiles hashtable.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration)
    $errors=[Collections.Generic.List[string]]::new();$normalized=[ordered]@{Profiles=[ordered]@{}}
    $keys=@(if($Configuration-is[Collections.IDictionary]){$Configuration.Keys}else{$Configuration.PSObject.Properties.Name})
    if($keys.Count-eq 0){$errors.Add('Configuration cannot be empty.')}
    foreach($key in $keys){if($key-ne'Profiles'){$errors.Add("Unsupported top-level setting '$key'.")}}
    $profiles=if('Profiles'-in$keys){if($Configuration-is[Collections.IDictionary]){$Configuration.Profiles}else{$Configuration.Profiles}}else{$null}
    if($profiles-isnot[Collections.IDictionary]-or$profiles.Count-eq 0){$errors.Add('Profiles must be a non-empty hashtable.')}
    else{
        $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach($profileName in $profiles.Keys){
            if([string]::IsNullOrWhiteSpace([string]$profileName)){$errors.Add('Profile names cannot be empty.');continue}
            $items=@($profiles[$profileName]);$output=[Collections.Generic.List[object]]::new()
            if($items.Count-eq 0){$errors.Add("Profile '$profileName' cannot be empty.");continue}
            foreach($item in $items){
                $itemKeys=@(if($item-is[Collections.IDictionary]){$item.Keys}else{$item.PSObject.Properties.Name})
                foreach($itemKey in $itemKeys){if($itemKey-notin@('Id','Source')){$errors.Add("Package in '$profileName' has unsupported setting '$itemKey'.")}}
                $id=if($itemKeys-contains'Id'){[string]$item.Id}else{''}
                $source=if($itemKeys-contains'Source'){[string]$item.Source}else{'winget'}
                if([string]::IsNullOrWhiteSpace($id)){$errors.Add("Package in '$profileName' requires an Id.");continue}
                if($source-notin@('winget','msstore')){$errors.Add("Package '$id' uses unsupported source '$source'.");continue}
                if(-not$seen.Add($id)){$errors.Add("Package '$id' is duplicated across profiles.");continue}
                $output.Add([pscustomobject]@{Id=$id;Source=$source})
            }
            $normalized.Profiles[$profileName]=@($output)
        }
    }
    [pscustomobject]@{IsValid=$errors.Count-eq 0;Errors=@($errors);Configuration=$normalized}
}

function Get-HermesWingetPackages {
    <#
    .SYNOPSIS Audits approved packages and returns their installed state.
    .PARAMETER Configuration Hermes WinGet configuration.
    .PARAMETER Profile Optional profile names to audit.
    #>
    [CmdletBinding()][OutputType([object[]])]
    param([Parameter(Mandatory)][object]$Configuration,[string[]]$Profile)
    $packageParameters=@{Configuration=$Configuration}
    if($PSBoundParameters.ContainsKey('Profile')){
        $packageParameters.ProfileName=@($PSBoundParameters['Profile'])
    }
    $packages=@(ConvertTo-HermesWingetPackageList @packageParameters)
    foreach($package in $packages){
        $result=Invoke-HermesWinget -Arguments @('list','--id',$package.Id,'--exact','--source',$package.Source,'--accept-source-agreements','--disable-interactivity')
        [pscustomobject]@{
            Profile=$package.Profile
            Id=$package.Id
            Source=$package.Source
            Installed=($result.ExitCode -eq 0 -and $result.Text -match [regex]::Escape($package.Id))
            Details=$result.Text
        }
    }
}

function Test-HermesWingetPackages {
    <#
    .SYNOPSIS Tests whether all selected Hermes packages are installed.
    .PARAMETER Configuration Hermes WinGet configuration.
    .PARAMETER Profile Optional profile names.
    .PARAMETER Inventory Optional pre-collected inventory for deterministic testing or offline review.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string[]]$Profile,[object[]]$Inventory)
    $validation=Test-HermesWingetConfiguration $Configuration
    if(-not$validation.IsValid){throw($validation.Errors-join[Environment]::NewLine)}
    $selectedProfiles=if($PSBoundParameters.ContainsKey('Profile') -and @($PSBoundParameters['Profile']).Count -gt 0){@($PSBoundParameters['Profile'])}else{@($validation.Configuration.Profiles.Keys)}
    if($PSBoundParameters.ContainsKey('Inventory')){
        $current=@($Inventory)
    }
    else{
        $auditParameters=@{Configuration=$Configuration}
        if($PSBoundParameters.ContainsKey('Profile')){
            $auditParameters.Profile=@($PSBoundParameters['Profile'])
        }
        $current=@(Get-HermesWingetPackages @auditParameters)
    }
    $missing=@()
    foreach($profileName in $selectedProfiles){
        $profileKey=[string]$profileName
        if(@($validation.Configuration.Profiles.Keys) -inotcontains $profileKey){throw "Unknown package profile '$profileKey'."}
        foreach($package in @($validation.Configuration.Profiles[$profileKey])){
            $installed=$false
            foreach($item in $current){
                if(([string]$item.Id) -ieq ([string]$package.Id) -and [bool]$item.Installed){
                    $installed=$true
                    break
                }
            }
            if(-not$installed){
                $missing+=[pscustomobject]@{Profile=$profileKey;Id=$package.Id;Source=$package.Source}
            }
        }
    }
    [bool]$isCompliant=($missing.Count -eq 0)
    [pscustomobject]@{IsCompliant=$isCompliant;Packages=@($current);Missing=@($missing)}
}

function Export-HermesWingetInventory {
    <#
    .SYNOPSIS Exports a WinGet inventory to a UTF-8 JSON file.
    .PARAMETER Path Destination JSON path.
    .PARAMETER Inventory Optional inventory objects. When omitted, WinGet's full list output is captured.
    #>
    [CmdletBinding(SupportsShouldProcess)][OutputType([IO.FileInfo])]
    param([Parameter(Mandatory)][string]$Path,[object[]]$Inventory)
    $resolved=[IO.Path]::GetFullPath($Path)
    $data=if($PSBoundParameters.ContainsKey('Inventory')){@($Inventory)}else{
        $result=Invoke-HermesWinget -Arguments @('list','--source','winget','--accept-source-agreements','--disable-interactivity')
        [pscustomobject]@{CapturedAt=(Get-Date).ToString('o');ExitCode=$result.ExitCode;Output=$result.Output}
    }
    if($PSCmdlet.ShouldProcess($resolved,'Export WinGet inventory')){
        $directory=Split-Path $resolved -Parent
        if(-not(Test-Path $directory -PathType Container)){New-Item -ItemType Directory $directory -Force|Out-Null}
        [IO.File]::WriteAllText($resolved,($data|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
        Get-Item $resolved
    }
}

function Install-HermesWingetPackages {
    <#
    .SYNOPSIS Installs only missing packages from selected Hermes profiles.
    .PARAMETER Configuration Hermes WinGet configuration.
    .PARAMETER Profile Optional profile names.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[string[]]$Profile)
    $testParameters=@{Configuration=$Configuration}
    if($PSBoundParameters.ContainsKey('Profile')){
        $testParameters.Profile=@($PSBoundParameters['Profile'])
    }
    $before=Test-HermesWingetPackages @testParameters
    $results=[Collections.Generic.List[object]]::new()
    foreach($package in $before.Missing){
        if(-not$PSCmdlet.ShouldProcess($package.Id,"Install from $($package.Source)")){continue}
        $result=Invoke-HermesWinget -Arguments @('install','--id',$package.Id,'--exact','--source',$package.Source,'--accept-source-agreements','--accept-package-agreements','--disable-interactivity')
        $results.Add([pscustomobject]@{Id=$package.Id;ExitCode=$result.ExitCode;Succeeded=($result.ExitCode -eq 0);Output=$result.Text})
        if($result.ExitCode-ne 0){throw "WinGet failed to install '$($package.Id)'. $($result.Text)"}
    }
    $after=if($WhatIfPreference){$before}else{Test-HermesWingetPackages @testParameters}
    [pscustomobject]@{Changed=$results.Count-gt 0;Installed=@($results);Verification=$after}
}

function Get-HermesWingetUpgrades {
    <#
    .SYNOPSIS Reports available WinGet upgrades without installing them.
    .PARAMETER Source WinGet source to query.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([ValidateSet('winget','msstore')][string]$Source='winget')
    $result=Invoke-HermesWinget -Arguments @('upgrade','--source',$Source,'--accept-source-agreements','--disable-interactivity')
    [pscustomobject]@{Source=$Source;ExitCode=$result.ExitCode;Output=$result.Output;Text=$result.Text}
}

Export-ModuleMember -Function @(
    'Get-HermesWingetPackages'
    'Test-HermesWingetConfiguration'
    'Test-HermesWingetPackages'
    'Export-HermesWingetInventory'
    'Install-HermesWingetPackages'
    'Get-HermesWingetUpgrades'
)
