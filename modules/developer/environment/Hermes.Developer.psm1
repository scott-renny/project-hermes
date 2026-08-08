Set-StrictMode -Version Latest

$script:SupportedTopLevelSettings = @(
    'Tools'
    'VSCodeExtensions'
    'SshAgent'
    'RemoteHosts'
    'OptionalCapabilities'
)

function Get-HermesObjectKeys {
    param([object]$InputObject)
    if ($InputObject -is [Collections.IDictionary]) { return @($InputObject.Keys) }
    @($InputObject.PSObject.Properties.Name)
}

function Get-HermesObjectValue {
    param([object]$InputObject,[string]$Name)
    if ($InputObject -is [Collections.IDictionary]) { return $InputObject[$Name] }
    $InputObject.$Name
}

function Invoke-HermesDeveloperCommand {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [int[]]$AllowedExitCodes = @(0)
    )

    $application = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $application) {
        return [pscustomobject]@{ Found=$false;Path=$null;ExitCode=$null;Output='';Error='' }
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $application.Source
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add([string]$argument) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) { throw "Unable to start '$Command'." }
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }

    [pscustomobject]@{
        Found    = $true
        Path     = $application.Source
        ExitCode = $exitCode
        Output   = $output.Trim()
        Error    = $errorOutput.Trim()
        Succeeded = ($exitCode -in $AllowedExitCodes)
    }
}

function Get-HermesSshAliases {
    [CmdletBinding()][OutputType([string[]])]
    param([string]$Path = (Join-Path $HOME '.ssh\config'))

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $aliases = [Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*Host\s+(.+?)\s*$') {
            foreach ($alias in ($Matches[1] -split '\s+')) {
                if ($alias -notmatch '[*?!]') { $aliases.Add($alias) }
            }
        }
    }
    @($aliases | Sort-Object -Unique)
}

function Test-HermesDeveloperConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes a Project Hermes developer-environment configuration.
    .PARAMETER Configuration
        Developer configuration to validate.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $keys = @(Get-HermesObjectKeys $Configuration)
    if ($keys.Count -eq 0) { $errors.Add('Developer configuration cannot be empty.') }
    foreach ($key in $keys | Where-Object { $_ -notin $script:SupportedTopLevelSettings }) {
        $errors.Add("Unsupported developer setting '$key'.")
    }

    $normalized = [ordered]@{
        Tools = @()
        VSCodeExtensions = @()
        SshAgent = [ordered]@{Required=$false;StartupType='Automatic';MinimumLoadedKeys=0}
        RemoteHosts = @()
        OptionalCapabilities = @()
    }

    if ('Tools' -notin $keys -or @(Get-HermesObjectValue $Configuration 'Tools').Count -eq 0) {
        $errors.Add('Tools must contain at least one required tool.')
    }
    else {
        $seenCommands = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $tools = [Collections.Generic.List[object]]::new()
        foreach ($tool in @(Get-HermesObjectValue $Configuration 'Tools')) {
            $toolKeys = @(Get-HermesObjectKeys $tool)
            foreach ($key in $toolKeys | Where-Object { $_ -notin @('Name','Command','VersionArguments','PackageId','Source') }) {
                $errors.Add("Tool contains unsupported setting '$key'.")
            }
            $name = [string](Get-HermesObjectValue $tool 'Name')
            $command = [string](Get-HermesObjectValue $tool 'Command')
            if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($command)) {
                $errors.Add('Every tool requires non-empty Name and Command values.')
                continue
            }
            if (-not $seenCommands.Add($command)) {
                $errors.Add("Tool command '$command' is duplicated.")
                continue
            }
            $source = if ('Source' -in $toolKeys) { [string](Get-HermesObjectValue $tool 'Source') } else { 'winget' }
            if ($source -notin @('winget','msstore')) { $errors.Add("Tool '$name' uses unsupported source '$source'.") }
            $tools.Add([pscustomobject]@{
                Name=$name.Trim();Command=$command.Trim()
                VersionArguments=@(if('VersionArguments' -in $toolKeys){Get-HermesObjectValue $tool 'VersionArguments'}else{'--version'})
                PackageId=if('PackageId' -in $toolKeys){[string](Get-HermesObjectValue $tool 'PackageId')}else{''}
                Source=$source
            })
        }
        $normalized.Tools = @($tools)
    }

    if ('VSCodeExtensions' -in $keys) {
        $extensions = @((Get-HermesObjectValue $Configuration 'VSCodeExtensions') | ForEach-Object {[string]$_})
        if ($extensions | Where-Object {[string]::IsNullOrWhiteSpace($_)}) { $errors.Add('VSCodeExtensions cannot contain empty values.') }
        if (@($extensions | Sort-Object -Unique).Count -ne $extensions.Count) { $errors.Add('VSCodeExtensions cannot contain duplicates.') }
        $normalized.VSCodeExtensions = @($extensions)
    }

    if ('SshAgent' -in $keys) {
        $agent = Get-HermesObjectValue $Configuration 'SshAgent'
        $agentKeys = @(Get-HermesObjectKeys $agent)
        foreach ($key in $agentKeys | Where-Object { $_ -notin @('Required','StartupType','MinimumLoadedKeys') }) {
            $errors.Add("SshAgent contains unsupported setting '$key'.")
        }
        $minimum = if ('MinimumLoadedKeys' -in $agentKeys) {[int](Get-HermesObjectValue $agent 'MinimumLoadedKeys')}else{0}
        if ($minimum -lt 0) { $errors.Add('SshAgent.MinimumLoadedKeys cannot be negative.') }
        $startup = if ('StartupType' -in $agentKeys) {[string](Get-HermesObjectValue $agent 'StartupType')}else{'Automatic'}
        if ($startup -notin @('Automatic','Manual','Disabled')) { $errors.Add('SshAgent.StartupType must be Automatic, Manual, or Disabled.') }
        $normalized.SshAgent = [ordered]@{
            Required=if('Required' -in $agentKeys){[bool](Get-HermesObjectValue $agent 'Required')}else{$false}
            StartupType=$startup
            MinimumLoadedKeys=$minimum
        }
    }

    if ('RemoteHosts' -in $keys) {
        $hosts = @((Get-HermesObjectValue $Configuration 'RemoteHosts') | ForEach-Object {[string]$_})
        if ($hosts | Where-Object {[string]::IsNullOrWhiteSpace($_)}) { $errors.Add('RemoteHosts cannot contain empty values.') }
        if (@($hosts | Sort-Object -Unique).Count -ne $hosts.Count) { $errors.Add('RemoteHosts cannot contain duplicates.') }
        $normalized.RemoteHosts = @($hosts)
    }

    if ('OptionalCapabilities' -in $keys) {
        $capabilities = [Collections.Generic.List[object]]::new()
        foreach ($capability in @(Get-HermesObjectValue $Configuration 'OptionalCapabilities')) {
            $capabilityKeys = @(Get-HermesObjectKeys $capability)
            foreach ($key in $capabilityKeys | Where-Object { $_ -notin @('Name','Command','ProbeArguments') }) {
                $errors.Add("Optional capability contains unsupported setting '$key'.")
            }
            $name = [string](Get-HermesObjectValue $capability 'Name')
            $command = [string](Get-HermesObjectValue $capability 'Command')
            if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($command)) {
                $errors.Add('Every optional capability requires non-empty Name and Command values.')
                continue
            }
            $capabilities.Add([pscustomobject]@{
                Name=$name.Trim()
                Command=$command.Trim()
                ProbeArguments=@(if('ProbeArguments' -in $capabilityKeys){Get-HermesObjectValue $capability 'ProbeArguments'}else{@()})
            })
        }
        $normalized.OptionalCapabilities = @($capabilities)
    }

    [pscustomobject]@{IsValid=($errors.Count -eq 0);Errors=@($errors);Configuration=$normalized}
}

function Get-HermesDeveloperEnvironment {
    <#
    .SYNOPSIS
        Collects the current Project Hermes developer-environment inventory.
    .PARAMETER Configuration
        Developer configuration defining required and optional capabilities.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration)

    $validation = Test-HermesDeveloperConfiguration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join [Environment]::NewLine) }

    $tools = foreach ($tool in $validation.Configuration.Tools) {
        $result = Invoke-HermesDeveloperCommand -Command $tool.Command -Arguments $tool.VersionArguments
        $version = if ($result.Found -and $result.ExitCode -eq 0) {
            @($result.Output,$result.Error | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})[0] -split "`r?`n" | Select-Object -First 1
        } else { $null }
        [pscustomobject]@{Name=$tool.Name;Command=$tool.Command;Installed=($result.Found -and $result.ExitCode -eq 0);Version=$version;Path=$result.Path;PackageId=$tool.PackageId;Source=$tool.Source}
    }

    $codeExtensions = @()
    $code = Invoke-HermesDeveloperCommand -Command 'code' -Arguments @('--list-extensions','--show-versions')
    if ($code.Found -and $code.ExitCode -eq 0) {
        $codeExtensions = @($code.Output -split "`r?`n" | Where-Object {$_} | ForEach-Object {($_ -split '@')[0].ToLowerInvariant()})
    }

    $service = Get-Service -Name 'ssh-agent' -ErrorAction SilentlyContinue
    $keyResult = Invoke-HermesDeveloperCommand -Command 'ssh-add' -Arguments @('-l') -AllowedExitCodes @(0,1,2)
    $keys = if ($keyResult.ExitCode -eq 0) {@($keyResult.Output -split "`r?`n" | Where-Object {$_})}else{@()}

    $aliases = @(Get-HermesSshAliases)
    $optional = foreach ($capability in $validation.Configuration.OptionalCapabilities) {
        $command = Get-Command $capability.Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        $detected = ($null -ne $command)
        $probe = $null
        if ($detected -and @($capability.ProbeArguments).Count -gt 0) {
            $probe = Invoke-HermesDeveloperCommand -Command $capability.Command -Arguments $capability.ProbeArguments
        }
        $operational = if (-not $detected) {$false}elseif($null -eq $probe){$null}else{[bool]($probe.ExitCode -eq 0)}
        $status = if (-not $detected) {'NotInstalled'}elseif($null -eq $probe){'DetectedNotValidated'}elseif($operational){'Operational'}else{'DetectedButUnavailable'}
        [pscustomobject]@{
            Name=$capability.Name
            Command=$capability.Command
            Detected=$detected
            Operational=$operational
            Status=$status
            Path=if($command){$command.Source}else{$null}
            Details=if($null -ne $probe){@($probe.Output,$probe.Error | Where-Object {$_}) -join [Environment]::NewLine}else{''}
        }
    }

    [pscustomobject]@{
        CapturedAt=(Get-Date).ToString('o')
        Tools=@($tools)
        VSCodeExtensions=@($codeExtensions)
        SshAgent=[pscustomobject]@{
            Exists=($null -ne $service)
            Status=if($service){[string]$service.Status}else{'NotInstalled'}
            StartupType=if($service){[string]$service.StartType}else{'NotInstalled'}
            LoadedKeys=@($keys)
        }
        RemoteHosts=@($aliases)
        OptionalCapabilities=@($optional)
    }
}

function Test-HermesDeveloperEnvironment {
    <#
    .SYNOPSIS
        Compares a developer-environment inventory with the Project Hermes baseline.
    .PARAMETER Configuration
        Desired developer configuration.
    .PARAMETER Inventory
        Optional pre-collected inventory for deterministic tests or offline review.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[object]$Inventory)

    $validation = Test-HermesDeveloperConfiguration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join [Environment]::NewLine) }
    $current = if ($PSBoundParameters.ContainsKey('Inventory')) {$Inventory}else{Get-HermesDeveloperEnvironment $validation.Configuration}
    $differences = [Collections.Generic.List[object]]::new()

    foreach ($tool in $validation.Configuration.Tools) {
        $state = @($current.Tools | Where-Object {$_.Command -ieq $tool.Command}) | Select-Object -First 1
        if ($null -eq $state -or -not [bool]$state.Installed) {
            $differences.Add([pscustomobject]@{Category='Tool';Name=$tool.Name;Expected='Installed';Actual='NotInstalled';PackageId=$tool.PackageId})
        }
    }
    foreach ($extension in $validation.Configuration.VSCodeExtensions) {
        if (@($current.VSCodeExtensions) -inotcontains $extension) {
            $differences.Add([pscustomobject]@{Category='VSCodeExtension';Name=$extension;Expected='Installed';Actual='NotInstalled';PackageId=''})
        }
    }
    if ($validation.Configuration.SshAgent.Required) {
        if (-not [bool]$current.SshAgent.Exists) {
            $differences.Add([pscustomobject]@{Category='SshAgent';Name='ssh-agent';Expected='Installed';Actual='NotInstalled';PackageId=''})
        }
        elseif ([string]$current.SshAgent.Status -ne 'Running') {
            $differences.Add([pscustomobject]@{Category='SshAgent';Name='ssh-agent';Expected='Running';Actual=[string]$current.SshAgent.Status;PackageId=''})
        }
        if ([string]$current.SshAgent.StartupType -ne $validation.Configuration.SshAgent.StartupType) {
            $differences.Add([pscustomobject]@{Category='SshAgent';Name='StartupType';Expected=$validation.Configuration.SshAgent.StartupType;Actual=[string]$current.SshAgent.StartupType;PackageId=''})
        }
        if (@($current.SshAgent.LoadedKeys).Count -lt $validation.Configuration.SshAgent.MinimumLoadedKeys) {
            $differences.Add([pscustomobject]@{Category='SshAgent';Name='LoadedKeys';Expected=$validation.Configuration.SshAgent.MinimumLoadedKeys;Actual=@($current.SshAgent.LoadedKeys).Count;PackageId=''})
        }
    }
    foreach ($hostName in $validation.Configuration.RemoteHosts) {
        if (@($current.RemoteHosts) -inotcontains $hostName) {
            $differences.Add([pscustomobject]@{Category='RemoteHost';Name=$hostName;Expected='Configured';Actual='NotConfigured';PackageId=''})
        }
    }

    [pscustomobject]@{IsCompliant=($differences.Count -eq 0);Current=$current;Desired=$validation.Configuration;Differences=@($differences)}
}

function Set-HermesDeveloperEnvironment {
    <#
    .SYNOPSIS
        Installs missing required packages and VS Code extensions with explicit preview support.
    .PARAMETER Configuration
        Desired developer configuration.
    .PARAMETER Inventory
        Optional pre-collected inventory, primarily for deterministic preview and testing.
    #>
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][object]$Configuration,[object]$Inventory)

    $testParameters = @{Configuration=$Configuration}
    if ($PSBoundParameters.ContainsKey('Inventory')) {$testParameters.Inventory=$Inventory}
    $before = Test-HermesDeveloperEnvironment @testParameters
    $actions = [Collections.Generic.List[object]]::new()

    foreach ($difference in $before.Differences) {
        if ($difference.Category -eq 'Tool' -and -not [string]::IsNullOrWhiteSpace([string]$difference.PackageId)) {
            $tool = $before.Desired.Tools | Where-Object {$_.PackageId -eq $difference.PackageId} | Select-Object -First 1
            $actions.Add([pscustomobject]@{Type='Package';Name=$difference.PackageId;Source=$tool.Source})
            if ($PSCmdlet.ShouldProcess($difference.PackageId,"Install from $($tool.Source)")) {
                $result = Invoke-HermesDeveloperCommand -Command 'winget' -Arguments @('install','--id',$difference.PackageId,'--exact','--source',$tool.Source,'--accept-source-agreements','--accept-package-agreements','--disable-interactivity')
                if (-not $result.Succeeded) { throw "Unable to install '$($difference.PackageId)'. $($result.Error)" }
            }
        }
        elseif ($difference.Category -eq 'VSCodeExtension') {
            $actions.Add([pscustomobject]@{Type='VSCodeExtension';Name=$difference.Name;Source='Visual Studio Marketplace'})
            if ($PSCmdlet.ShouldProcess($difference.Name,'Install Visual Studio Code extension')) {
                $result = Invoke-HermesDeveloperCommand -Command 'code' -Arguments @('--install-extension',$difference.Name,'--force')
                if (-not $result.Succeeded) { throw "Unable to install VS Code extension '$($difference.Name)'. $($result.Error)" }
            }
        }
    }

    $verification = if ($WhatIfPreference -or $PSBoundParameters.ContainsKey('Inventory')) {$before}else{Test-HermesDeveloperEnvironment $Configuration}
    [pscustomobject]@{Changed=($actions.Count -gt 0 -and -not $WhatIfPreference);PlannedActions=@($actions);Before=$before;Verification=$verification}
}

function Export-HermesDeveloperInventory {
    <#
    .SYNOPSIS
        Exports a developer-environment inventory to UTF-8 JSON.
    .PARAMETER Path
        Destination JSON path.
    .PARAMETER Inventory
        Inventory object to export.
    #>
    [CmdletBinding(SupportsShouldProcess)][OutputType([IO.FileInfo])]
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Inventory)

    $resolved = [IO.Path]::GetFullPath($Path)
    if ($PSCmdlet.ShouldProcess($resolved,'Export Hermes developer inventory')) {
        $directory = Split-Path $resolved -Parent
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {New-Item -ItemType Directory -Path $directory -Force | Out-Null}
        [IO.File]::WriteAllText($resolved,($Inventory | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
        Get-Item -LiteralPath $resolved
    }
}

function Test-HermesRemoteHost {
    <#
    .SYNOPSIS
        Performs a bounded non-interactive SSH connectivity test for a configured remote host.
    .PARAMETER HostName
        SSH configuration alias to test.
    .PARAMETER ConnectTimeoutSeconds
        Maximum SSH connection time in seconds.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$HostName,[ValidateRange(1,60)][int]$ConnectTimeoutSeconds=5)

    $arguments = @('-o','BatchMode=yes','-o',"ConnectTimeout=$ConnectTimeoutSeconds",$HostName,'true')
    $result = Invoke-HermesDeveloperCommand -Command 'ssh' -Arguments $arguments
    [pscustomobject]@{HostName=$HostName;Reachable=($result.Found -and $result.ExitCode -eq 0);ExitCode=$result.ExitCode;Error=$result.Error}
}

Export-ModuleMember -Function @(
    'Get-HermesDeveloperEnvironment'
    'Test-HermesDeveloperConfiguration'
    'Test-HermesDeveloperEnvironment'
    'Set-HermesDeveloperEnvironment'
    'Export-HermesDeveloperInventory'
    'Test-HermesRemoteHost'
)
