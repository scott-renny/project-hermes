Set-StrictMode -Version Latest

$script:ModuleName = 'Hermes.PowerShell'
$script:StartMarker = '# >>> Project Hermes managed profile >>>'
$script:EndMarker = '# <<< Project Hermes managed profile <<<'
$script:SupportedModules = [ordered]@{
    'Hermes.Common'   = 'modules\common\Hermes.Common.psd1'
    'Hermes.Explorer' = 'modules\workstation\explorer\Hermes.Explorer.psd1'
    'Hermes.Taskbar'  = 'modules\workstation\taskbar\Hermes.Taskbar.psd1'
    'Hermes.Windows'  = 'modules\workstation\windows\Hermes.Windows.psd1'
    'Hermes.Desktop'  = 'modules\workstation\desktop\Hermes.Desktop.psd1'
    'Hermes.Terminal' = 'modules\workstation\terminal\Hermes.Terminal.psd1'
    'Hermes.Git'      = 'modules\workstation\git\Hermes.Git.psd1'
    'Hermes.VSCode'   = 'modules\workstation\vscode\Hermes.VSCode.psd1'
    'Hermes.PowerToys' = 'modules\workstation\powertoys\Hermes.PowerToys.psd1'
    'Hermes.Winget'   = 'modules\workstation\winget\Hermes.Winget.psd1'
}

$coreManifest = Join-Path $PSScriptRoot '..\..\core\Hermes.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Hermes.Core could not be found at '$coreManifest'."
}
Import-Module $coreManifest -Force -ErrorAction Stop

function Get-HermesPowerShellProfilePath {
    [CmdletBinding()][OutputType([string])]
    param([string]$ProfilePath)

    if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
        return [IO.Path]::GetFullPath($PROFILE.CurrentUserAllHosts)
    }
    [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($ProfilePath))
}

function Get-HermesManagedProfileBlock {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string[]]$Modules
    )

    $escapedRoot = $RepositoryRoot.Replace("'", "''")
    $moduleLines = foreach ($name in $Modules) {
        "    '$($script:SupportedModules[$name])'"
    }

    @"
$($script:StartMarker)
# RepositoryRoot: $RepositoryRoot
# Modules: $($Modules -join ',')
`$hermesRepositoryRoot = '$escapedRoot'
`$hermesModuleManifests = @(
$($moduleLines -join "`n")
)

foreach (`$hermesRelativeManifest in `$hermesModuleManifests) {
    `$hermesManifest = Join-Path `$hermesRepositoryRoot `$hermesRelativeManifest

    if (Test-Path -LiteralPath `$hermesManifest -PathType Leaf) {
        Import-Module `$hermesManifest -ErrorAction Stop
    }
    else {
        Write-Warning "Project Hermes module manifest was not found: '`$hermesManifest'."
    }
}
$($script:EndMarker)
"@.Trim()
}

function Get-HermesProfileText {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $content = Get-Content `
        -LiteralPath $Path `
        -Raw `
        -Encoding UTF8 `
        -ErrorAction Stop

    if ($null -eq $content) {
        Write-Output -NoEnumerate ([string]::Empty)
        return
    }
    [string]$content
}

function ConvertTo-HermesProfileText {
    [CmdletBinding()][OutputType([string])]
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return [string]::Empty }
    [string]$Value
}

function Get-HermesPowerShellSettings {
    <#
    .SYNOPSIS
        Reads the Project Hermes state from a PowerShell user profile.
    .PARAMETER ProfilePath
        Optional profile path. Defaults to the current user's all-hosts profile.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$ProfilePath)

    $path = Get-HermesPowerShellProfilePath -ProfilePath $ProfilePath
    $text = ConvertTo-HermesProfileText `
        -Value (Get-HermesProfileText -Path $path)
    $present = $text.Contains($script:StartMarker) -and $text.Contains($script:EndMarker)
    $root = $null
    $modules = @()

    if ($present) {
        if ($text -match '(?m)^# RepositoryRoot: (.+)$') { $root = $Matches[1].Trim() }
        if ($text -match '(?m)^# Modules: (.*)$') {
            $modules = @($Matches[1].Split(',',[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() })
        }
    }

    [pscustomobject]@{
        ProfilePath = $path
        ProfileExists = Test-Path -LiteralPath $path -PathType Leaf
        ManagedBlock = if ($present) { 'Present' } else { 'Absent' }
        RepositoryRoot = $root
        Modules = $modules
    }
}

function Test-HermesPowerShellConfiguration {
    <#
    .SYNOPSIS
        Validates and normalizes a Hermes PowerShell profile configuration.
    .PARAMETER Configuration
        Object containing a non-empty Modules collection.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][ValidateNotNull()][object]$Configuration)

    $errors = [Collections.Generic.List[string]]::new()
    $properties = @(if ($Configuration -is [Collections.IDictionary]) { $Configuration.Keys } else { $Configuration.PSObject.Properties.Name })
    $unsupported = @($properties | Where-Object { $_ -ne 'Modules' })
    foreach ($name in $unsupported) { $errors.Add("Unsupported PowerShell profile setting '$name'.") }

    $rawModules = if ($properties -contains 'Modules') {
        if ($Configuration -is [Collections.IDictionary]) { $Configuration['Modules'] } else { $Configuration.Modules }
    } else { @() }
    $modules = @($rawModules | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

    if ($modules.Count -eq 0) { $errors.Add('Modules must contain at least one supported Hermes module.') }
    foreach ($name in $modules) {
        if (-not $script:SupportedModules.Contains($name)) { $errors.Add("Unsupported Hermes module '$name'.") }
    }

    [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
        Configuration = [ordered]@{ Modules = $modules }
    }
}

function Test-HermesPowerShellSettings {
    <#
    .SYNOPSIS
        Compares the managed PowerShell profile block with desired state.
    .PARAMETER Configuration
        Desired Hermes PowerShell profile configuration.
    .PARAMETER ProfilePath
        Optional profile path for validation or testing.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [string]$ProfilePath
    )

    $validation = Test-HermesPowerShellConfiguration -Configuration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }
    $path = Get-HermesPowerShellProfilePath -ProfilePath $ProfilePath
    $root = Get-HermesRepositoryRoot
    $desiredBlock = Get-HermesManagedProfileBlock -RepositoryRoot $root -Modules $validation.Configuration.Modules
    $text = ConvertTo-HermesProfileText `
        -Value (Get-HermesProfileText -Path $path)
    $compliant = $text.Contains($desiredBlock)

    [pscustomobject]@{
        IsCompliant = $compliant
        Current = Get-HermesPowerShellSettings -ProfilePath $path
        Desired = [pscustomobject]@{ ProfilePath=$path; RepositoryRoot=$root; Modules=$validation.Configuration.Modules }
        Differences = @(if (-not $compliant) { [pscustomobject]@{ Setting='ManagedBlock'; Expected='Current'; Actual='MissingOrDifferent' } })
    }
}

function Backup-HermesPowerShellSettings {
    <#
    .SYNOPSIS
        Backs up the complete target PowerShell profile before modification.
    #>
    [CmdletBinding()][OutputType([pscustomobject])]
    param([string]$ProfilePath, [string]$BackupDirectory)

    $path = Get-HermesPowerShellProfilePath -ProfilePath $ProfilePath
    $exists = Test-Path -LiteralPath $path -PathType Leaf
    $text = if ($exists) {
        ConvertTo-HermesProfileText `
            -Value (Get-HermesProfileText -Path $path)
    }
    else { [string]::Empty }
    $parameters = @{
        ModuleName = 'Hermes.PowerShell'
        Settings = [pscustomobject]@{
            ProfilePath = $path
            Existed = $exists
            ContentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text))
        }
    }
    if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $parameters.BackupDirectory = $BackupDirectory }
    Write-HermesBackup @parameters
}

function Set-HermesPowerShellSettings {
    <#
    .SYNOPSIS
        Adds or replaces only the managed Project Hermes profile block.
    .PARAMETER Configuration
        Desired modules to import in new PowerShell sessions.
    .PARAMETER ProfilePath
        Optional profile path. Defaults to the current user's all-hosts profile.
    .PARAMETER BackupDirectory
        Optional backup destination.
    .PARAMETER SkipBackup
        Suppresses the automatic safety backup.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][object]$Configuration,
        [string]$ProfilePath,
        [string]$BackupDirectory,
        [switch]$SkipBackup
    )

    $validation = Test-HermesPowerShellConfiguration -Configuration $Configuration
    if (-not $validation.IsValid) { throw ($validation.Errors -join ' ') }
    $path = Get-HermesPowerShellProfilePath -ProfilePath $ProfilePath
    $precheck = Test-HermesPowerShellSettings -Configuration $validation.Configuration -ProfilePath $path
    if ($precheck.IsCompliant) { return [pscustomobject]@{ Changed=$false; Backup=$null; ProfilePath=$path; Verification=$precheck } }
    if (-not $PSCmdlet.ShouldProcess($path,'Install Project Hermes managed profile block')) { return }

    $backup = $null
    if (-not $SkipBackup) {
        $bp = @{ ProfilePath=$path }
        if ($PSBoundParameters.ContainsKey('BackupDirectory')) { $bp.BackupDirectory=$BackupDirectory }
        $backup = Backup-HermesPowerShellSettings @bp
    }

    $existing = ConvertTo-HermesProfileText `
        -Value (Get-HermesProfileText -Path $path)
    $pattern = '(?s)\r?\n?' + [regex]::Escape($script:StartMarker) + '.*?' + [regex]::Escape($script:EndMarker) + '\r?\n?'
    $preserved = [regex]::Replace($existing,$pattern,"`n").TrimEnd()
    $block = Get-HermesManagedProfileBlock -RepositoryRoot (Get-HermesRepositoryRoot) -Modules $validation.Configuration.Modules
    $newText = if ([string]::IsNullOrWhiteSpace($preserved)) { "$block`n" } else { "$preserved`n`n$block`n" }

    try {
        $directory = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item `
                -ItemType Directory `
                -Path $directory `
                -Force `
                -ErrorAction Stop |
                Out-Null
        }

        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            throw "The PowerShell profile directory '$directory' was not created."
        }

        Set-Content `
            -LiteralPath $path `
            -Value $newText `
            -Encoding utf8NoBOM `
            -NoNewline `
            -Force `
            -ErrorAction Stop
    } catch { throw "Unable to update PowerShell profile '$path'. $($_.Exception.Message)" }

    $verification = Test-HermesPowerShellSettings -Configuration $validation.Configuration -ProfilePath $path
    if (-not $verification.IsCompliant) { throw 'Hermes PowerShell profile post-change verification failed.' }
    [pscustomobject]@{ Changed=$true; Backup=$backup; ProfilePath=$path; Verification=$verification }
}

function Restore-HermesPowerShellSettings {
    <#
    .SYNOPSIS
        Restores the complete PowerShell profile from a Hermes backup.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')][OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$BackupPath, [switch]$CreateSafetyBackup)

    $document = Read-HermesBackup -BackupPath $BackupPath -ExpectedModuleName $script:ModuleName
    $path = [string]$document.Settings.ProfilePath
    if (-not $PSCmdlet.ShouldProcess($path,"Restore from '$BackupPath'")) { return }
    $safety = if ($CreateSafetyBackup) { Backup-HermesPowerShellSettings -ProfilePath $path } else { $null }

    if ([bool]$document.Settings.Existed) {
        $bytes = [Convert]::FromBase64String([string]$document.Settings.ContentBase64)
        $directory = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
        }
        Set-Content `
            -LiteralPath $path `
            -Value $bytes `
            -AsByteStream `
            -Force `
            -ErrorAction Stop
    } else {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }

    [pscustomobject]@{ Changed=$true; SourceBackupPath=$BackupPath; SafetyBackup=$safety; ProfilePath=$path }
}

Export-ModuleMember -Function @(
    'Get-HermesPowerShellSettings','Test-HermesPowerShellConfiguration',
    'Test-HermesPowerShellSettings','Backup-HermesPowerShellSettings',
    'Set-HermesPowerShellSettings','Restore-HermesPowerShellSettings'
)
