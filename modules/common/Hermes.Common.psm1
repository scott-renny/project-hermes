Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Provides shared helper functions for Project Hermes modules.

.DESCRIPTION
    Hermes.Common centralizes reusable logging, environment validation,
    Windows Registry access, JSON serialization, and Windows Explorer shell
    restart behavior. The module contains no component-specific policy and is
    intended to be consumed by all Project Hermes modules.

.NOTES
    Module:  Hermes.Common
    Version: 0.1.0
    Author:  Scott Renny
    Target:  Windows PowerShell 5.1 and PowerShell 7+
#>

#region Module information

$script:HermesCommonName = 'Hermes.Common'
$script:HermesCommonVersion = [version]'0.1.0'
$script:Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

#endregion Module information

#region Private helper functions

function Resolve-HermesFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try {
        return [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "The path '$Path' is invalid. $($_.Exception.Message)"
    }
}

function Assert-HermesWindows {
    [CmdletBinding()]
    param()

    $IsWindowsPlatform = if ($PSVersionTable.PSVersion.Major -lt 6) {
        $true
    }
    else {
        [bool]$IsWindows
    }

    if (-not $IsWindowsPlatform) {
        throw 'This operation is supported only on Windows.'
    }
}

function Get-HermesExceptionMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $Messages = New-Object System.Collections.Generic.List[string]
    $Exception = $ErrorRecord.Exception

    while ($null -ne $Exception) {
        if (-not [string]::IsNullOrWhiteSpace($Exception.Message)) {
            $Messages.Add($Exception.Message)
        }

        $Exception = $Exception.InnerException
    }

    if ($Messages.Count -eq 0) {
        return [string]$ErrorRecord
    }

    return ($Messages -join ' ')
}

function Write-HermesConsoleEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Entry,

        [Parameter(Mandatory)]
        [ValidateSet('Debug', 'Information', 'Success', 'Warning', 'Error')]
        [string]$Level
    )

    switch ($Level) {
        'Debug' {
            Write-Debug $Entry
        }
        'Information' {
            Write-Host $Entry
        }
        'Success' {
            Write-Host $Entry -ForegroundColor Green
        }
        'Warning' {
            Write-Host $Entry -ForegroundColor Yellow
        }
        'Error' {
            Write-Host $Entry -ForegroundColor Red
        }
    }
}

function Test-HermesRegistryValueExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    try {
        Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop |
            Out-Null
        return $true
    }
    catch [System.Management.Automation.PSArgumentException] {
        return $false
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        return $false
    }
}

#endregion Private helper functions

#region Logging

function Write-HermesLog {
    <#
    .SYNOPSIS
        Writes a standardized Project Hermes log entry.

    .DESCRIPTION
        Creates a timestamped log entry, optionally writes it to the console,
        and optionally appends it to a UTF-8 log file. Parent directories for
        the log file are created automatically.

    .PARAMETER Message
        The message to record.

    .PARAMETER Level
        The severity level. Valid values are Debug, Information, Success,
        Warning, and Error.

    .PARAMETER LogPath
        Optional destination log file. Relative paths are resolved against the
        current working directory.

    .PARAMETER NoConsole
        Suppresses console output while retaining file output and the returned
        entry.

    .EXAMPLE
        Write-HermesLog -Message 'Explorer configuration applied.' -Level Success

    .EXAMPLE
        Write-HermesLog -Message 'Starting validation.' -LogPath '.\logs\hermes.log'

    .OUTPUTS
        System.String. The formatted log entry.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet('Debug', 'Information', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Information',

        [ValidateNotNullOrEmpty()]
        [string]$LogPath,

        [switch]$NoConsole
    )

    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Entry = '[{0}] [{1}] {2}' -f $Timestamp, $Level.ToUpperInvariant(), $Message

    if (-not $NoConsole) {
        Write-HermesConsoleEntry -Entry $Entry -Level $Level
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $ResolvedLogPath = Resolve-HermesFilePath -Path $LogPath
        $LogDirectory = Split-Path -Path $ResolvedLogPath -Parent

        try {
            if (-not [string]::IsNullOrWhiteSpace($LogDirectory)) {
                [System.IO.Directory]::CreateDirectory($LogDirectory) |
                    Out-Null
            }

            [System.IO.File]::AppendAllText(
                $ResolvedLogPath,
                $Entry + [Environment]::NewLine,
                $script:Utf8WithoutBom
            )
        }
        catch {
            throw "Failed to write Hermes log '$ResolvedLogPath'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }
    }

    return $Entry
}

function Write-HermesSuccess {
    <#
    .SYNOPSIS
        Writes a standardized success entry.

    .PARAMETER Message
        The success message to record.

    .PARAMETER LogPath
        Optional destination log file.

    .PARAMETER NoConsole
        Suppresses console output.

    .OUTPUTS
        System.String. The formatted log entry.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateNotNullOrEmpty()]
        [string]$LogPath,

        [switch]$NoConsole
    )

    $Parameters = @{
        Message = $Message
        Level = 'Success'
        NoConsole = $NoConsole
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $Parameters.LogPath = $LogPath
    }

    return Write-HermesLog @Parameters
}

function Write-HermesWarning {
    <#
    .SYNOPSIS
        Writes a standardized warning entry.

    .PARAMETER Message
        The warning message to record.

    .PARAMETER LogPath
        Optional destination log file.

    .PARAMETER NoConsole
        Suppresses console output.

    .OUTPUTS
        System.String. The formatted log entry.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateNotNullOrEmpty()]
        [string]$LogPath,

        [switch]$NoConsole
    )

    $Parameters = @{
        Message = $Message
        Level = 'Warning'
        NoConsole = $NoConsole
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $Parameters.LogPath = $LogPath
    }

    return Write-HermesLog @Parameters
}

function Write-HermesError {
    <#
    .SYNOPSIS
        Writes a standardized error entry.

    .DESCRIPTION
        Writes an error-level Hermes log entry. This function records an error
        message but does not throw or write to PowerShell's error stream; the
        caller remains responsible for terminating behavior.

    .PARAMETER Message
        The error message to record.

    .PARAMETER LogPath
        Optional destination log file.

    .PARAMETER NoConsole
        Suppresses console output.

    .OUTPUTS
        System.String. The formatted log entry.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateNotNullOrEmpty()]
        [string]$LogPath,

        [switch]$NoConsole
    )

    $Parameters = @{
        Message = $Message
        Level = 'Error'
        NoConsole = $NoConsole
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $Parameters.LogPath = $LogPath
    }

    return Write-HermesLog @Parameters
}

#endregion Logging

#region Validation

function Test-HermesAdministrator {
    <#
    .SYNOPSIS
        Determines whether the current process has administrator privileges.

    .DESCRIPTION
        Returns true when the current Windows identity belongs to the built-in
        Administrators role and the process is elevated. Returns false on
        non-Windows platforms or when the identity cannot be evaluated.

    .OUTPUTS
        System.Boolean.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not (Test-HermesOperatingSystem -OperatingSystem Windows)) {
        return $false
    }

    try {
        $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

        return $Principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    catch {
        Write-Verbose "Administrator detection failed: $(Get-HermesExceptionMessage -ErrorRecord $_)"
        return $false
    }
}

function Test-HermesOperatingSystem {
    <#
    .SYNOPSIS
        Tests the current operating-system platform.

    .PARAMETER OperatingSystem
        The required platform: Windows, Linux, or macOS.

    .OUTPUTS
        System.Boolean.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [ValidateSet('Windows', 'Linux', 'macOS')]
        [string]$OperatingSystem = 'Windows'
    )

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return $OperatingSystem -eq 'Windows'
    }

    switch ($OperatingSystem) {
        'Windows' { return [bool]$IsWindows }
        'Linux'   { return [bool]$IsLinux }
        'macOS'   { return [bool]$IsMacOS }
    }
}

function Test-HermesPowerShell {
    <#
    .SYNOPSIS
        Tests whether the active PowerShell version meets a minimum version.

    .PARAMETER MinimumVersion
        The minimum acceptable PowerShell version. The default is 5.1.

    .OUTPUTS
        System.Boolean.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [ValidateNotNull()]
        [version]$MinimumVersion = [version]'5.1'
    )

    return [version]$PSVersionTable.PSVersion -ge $MinimumVersion
}

#endregion Validation

#region Registry helpers

function Test-HermesRegistryPath {
    <#
    .SYNOPSIS
        Tests whether a Windows Registry key exists.

    .PARAMETER Path
        The PowerShell Registry provider path to test.

    .OUTPUTS
        System.Boolean.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-HermesOperatingSystem -OperatingSystem Windows)) {
        return $false
    }

    try {
        return Test-Path -LiteralPath $Path -PathType Container -ErrorAction Stop
    }
    catch {
        Write-Verbose "Registry path test failed for '$Path': $(Get-HermesExceptionMessage -ErrorRecord $_)"
        return $false
    }
}

function Get-HermesRegistryValue {
    <#
    .SYNOPSIS
        Retrieves a Windows Registry value.

    .PARAMETER Path
        The Registry key path.

    .PARAMETER Name
        The Registry value name.

    .PARAMETER DefaultValue
        The value returned when the key or named value does not exist.

    .PARAMETER ThrowOnMissing
        Throws when the key or named value does not exist instead of returning
        DefaultValue.

    .EXAMPLE
        Get-HermesRegistryValue -Path 'HKCU:\Software\Example' -Name 'Enabled' -DefaultValue 0

    .OUTPUTS
        The stored Registry value, or DefaultValue when not found.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [AllowNull()]
        [object]$DefaultValue = $null,

        [switch]$ThrowOnMissing
    )

    Assert-HermesWindows

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        if ($ThrowOnMissing) {
            throw "Registry path does not exist: $Path"
        }

        return $DefaultValue
    }

    try {
        $Item = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        return $Item.$Name
    }
    catch {
        if ($ThrowOnMissing) {
            throw "Registry value does not exist or could not be read: $Path\$Name. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }

        return $DefaultValue
    }
}

function Set-HermesRegistryValue {
    <#
    .SYNOPSIS
        Creates or updates a Windows Registry value.

    .DESCRIPTION
        Safely creates or updates a named Registry value. The key can be
        created when missing by using CreatePath. Supports WhatIf and Confirm.

    .PARAMETER Path
        The Registry key path.

    .PARAMETER Name
        The Registry value name.

    .PARAMETER Value
        The data to store.

    .PARAMETER Type
        The Registry value type. The default is String.

    .PARAMETER CreatePath
        Creates the Registry key when it does not exist.

    .EXAMPLE
        Set-HermesRegistryValue -Path 'HKCU:\Software\Example' -Name 'Enabled' -Value 1 -Type DWord -CreatePath

    .OUTPUTS
        PSCustomObject describing the requested value and whether it changed.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'String',

        [switch]$CreatePath
    )

    Assert-HermesWindows

    $PathExists = Test-Path -LiteralPath $Path -PathType Container

    if (-not $PathExists -and -not $CreatePath) {
        throw "Registry path does not exist: $Path. Use -CreatePath to create it."
    }

    $CurrentValueExists = $false
    $CurrentValue = $null

    if ($PathExists) {
        $CurrentValueExists = Test-HermesRegistryValueExists -Path $Path -Name $Name

        if ($CurrentValueExists) {
            $CurrentValue = Get-HermesRegistryValue -Path $Path -Name $Name -ThrowOnMissing
        }
    }

    $Changed = -not $CurrentValueExists -or -not [object]::Equals($CurrentValue, $Value)

    if (-not $Changed) {
        return [pscustomobject]@{
            PSTypeName = 'Hermes.RegistryResult'
            Path = $Path
            Name = $Name
            Value = $Value
            Type = $Type
            Changed = $false
            Applied = $false
        }
    }

    $Applied = $false

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set $Type Registry value to '$Value'")) {
        try {
            if (-not $PathExists) {
                New-Item -Path $Path -Force -ErrorAction Stop |
                    Out-Null
            }

            New-ItemProperty `
                -LiteralPath $Path `
                -Name $Name `
                -Value $Value `
                -PropertyType $Type `
                -Force `
                -ErrorAction Stop |
                Out-Null

            $Applied = $true
        }
        catch {
            throw "Failed to set Registry value '$Path\$Name'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }
    }

    return [pscustomobject]@{
        PSTypeName = 'Hermes.RegistryResult'
        Path = $Path
        Name = $Name
        Value = $Value
        Type = $Type
        Changed = $Changed
        Applied = $Applied
    }
}

function Remove-HermesRegistryValue {
    <#
    .SYNOPSIS
        Removes a named Windows Registry value.

    .PARAMETER Path
        The Registry key path.

    .PARAMETER Name
        The Registry value name.

    .PARAMETER IgnoreMissing
        Returns a no-change result when the key or value does not exist.

    .OUTPUTS
        PSCustomObject describing whether a value was found and removed.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [switch]$IgnoreMissing
    )

    Assert-HermesWindows

    $Exists = Test-HermesRegistryValueExists -Path $Path -Name $Name

    if (-not $Exists) {
        if (-not $IgnoreMissing) {
            throw "Registry value does not exist: $Path\$Name"
        }

        return [pscustomobject]@{
            PSTypeName = 'Hermes.RegistryRemovalResult'
            Path = $Path
            Name = $Name
            Existed = $false
            Removed = $false
        }
    }

    $Removed = $false

    if ($PSCmdlet.ShouldProcess("$Path\$Name", 'Remove Registry value')) {
        try {
            Remove-ItemProperty `
                -LiteralPath $Path `
                -Name $Name `
                -ErrorAction Stop
            $Removed = $true
        }
        catch {
            throw "Failed to remove Registry value '$Path\$Name'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }
    }

    return [pscustomobject]@{
        PSTypeName = 'Hermes.RegistryRemovalResult'
        Path = $Path
        Name = $Name
        Existed = $true
        Removed = $Removed
    }
}

#endregion Registry helpers

#region JSON helpers

function Export-HermesJson {
    <#
    .SYNOPSIS
        Serializes an object to a UTF-8 JSON file.

    .DESCRIPTION
        Serializes pipeline input to JSON, creates the parent directory when
        necessary, and writes UTF-8 without a byte-order mark. Existing files
        require Force. Supports WhatIf and Confirm.

    .PARAMETER InputObject
        The object to serialize.

    .PARAMETER Path
        The destination JSON file.

    .PARAMETER Depth
        The maximum serialization depth. The default is 10.

    .PARAMETER Force
        Overwrites an existing file.

    .EXAMPLE
        $Settings | Export-HermesJson -Path '.\exports\settings.json' -Force

    .OUTPUTS
        System.IO.FileInfo when written; otherwise no output for WhatIf.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateRange(1, 100)]
        [int]$Depth = 10,

        [switch]$Force
    )

    process {
        $ResolvedPath = Resolve-HermesFilePath -Path $Path

        if ((Test-Path -LiteralPath $ResolvedPath -PathType Leaf) -and -not $Force) {
            throw "File already exists: $ResolvedPath. Use -Force to overwrite it."
        }

        if (-not $PSCmdlet.ShouldProcess($ResolvedPath, 'Write JSON file')) {
            return
        }

        try {
            $ParentPath = Split-Path -Path $ResolvedPath -Parent

            if (-not [string]::IsNullOrWhiteSpace($ParentPath)) {
                [System.IO.Directory]::CreateDirectory($ParentPath) |
                    Out-Null
            }

            $Json = ConvertTo-Json -InputObject $InputObject -Depth $Depth
            [System.IO.File]::WriteAllText($ResolvedPath, $Json, $script:Utf8WithoutBom)

            return Get-Item -LiteralPath $ResolvedPath -ErrorAction Stop
        }
        catch {
            throw "Failed to export JSON to '$ResolvedPath'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }
    }
}

function Import-HermesJson {
    <#
    .SYNOPSIS
        Reads and deserializes a UTF-8 JSON file.

    .PARAMETER Path
        The source JSON file.

    .PARAMETER AsHashtable
        Returns a hashtable. This option requires PowerShell 6 or later.

    .EXAMPLE
        $Settings = Import-HermesJson -Path '.\config\settings.json'

    .OUTPUTS
        The object represented by the JSON document.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$AsHashtable
    )

    $ResolvedPath = Resolve-HermesFilePath -Path $Path

    if (-not (Test-Path -LiteralPath $ResolvedPath -PathType Leaf)) {
        throw "JSON file does not exist: $ResolvedPath"
    }

    try {
        $Content = [System.IO.File]::ReadAllText($ResolvedPath, [System.Text.Encoding]::UTF8)
    }
    catch {
        throw "Failed to read JSON file '$ResolvedPath'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
    }

    if ([string]::IsNullOrWhiteSpace($Content)) {
        throw "JSON file is empty: $ResolvedPath"
    }

    try {
        if ($AsHashtable) {
            $ConvertCommand = Get-Command ConvertFrom-Json -ErrorAction Stop

            if (-not $ConvertCommand.Parameters.ContainsKey('AsHashtable')) {
                throw '-AsHashtable requires PowerShell 6.0 or later.'
            }

            return ConvertFrom-Json -InputObject $Content -AsHashtable -ErrorAction Stop
        }

        return ConvertFrom-Json -InputObject $Content -ErrorAction Stop
    }
    catch {
        throw "Failed to parse JSON file '$ResolvedPath'. $(Get-HermesExceptionMessage -ErrorRecord $_)"
    }
}

#endregion JSON helpers

#region Windows Explorer helper

function Restart-HermesExplorer {
    <#
    .SYNOPSIS
        Restarts the Windows Explorer shell.

    .DESCRIPTION
        Stops all current explorer.exe processes and waits for the Windows
        shell to restart automatically. If it does not restart, the function
        starts explorer.exe explicitly and verifies that it becomes available.
        Supports WhatIf and Confirm.

    .PARAMETER TimeoutSeconds
        Maximum time to wait during each restart phase. The default is 10
        seconds.

    .EXAMPLE
        Restart-HermesExplorer

    .EXAMPLE
        Restart-HermesExplorer -WhatIf

    .OUTPUTS
        PSCustomObject describing whether restart was requested and completed.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [ValidateRange(1, 120)]
        [int]$TimeoutSeconds = 10
    )

    Assert-HermesWindows

    if (-not $PSCmdlet.ShouldProcess('explorer.exe', 'Restart Windows Explorer shell')) {
        return [pscustomobject]@{
            PSTypeName = 'Hermes.ExplorerRestartResult'
            Requested = $false
            Restarted = $false
            ProcessId = $null
        }
    }

    try {
        Get-Process -Name explorer -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction Stop
    }
    catch {
        throw "Failed to stop Windows Explorer. $(Get-HermesExceptionMessage -ErrorRecord $_)"
    }

    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $ExplorerProcess = $null

    do {
        Start-Sleep -Milliseconds 250
        $ExplorerProcess = Get-Process -Name explorer -ErrorAction SilentlyContinue |
            Select-Object -First 1
    }
    while ($null -eq $ExplorerProcess -and (Get-Date) -lt $Deadline)

    if ($null -eq $ExplorerProcess) {
        try {
            Start-Process -FilePath 'explorer.exe' -ErrorAction Stop |
                Out-Null
        }
        catch {
            throw "Failed to start Windows Explorer. $(Get-HermesExceptionMessage -ErrorRecord $_)"
        }

        $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)

        do {
            Start-Sleep -Milliseconds 250
            $ExplorerProcess = Get-Process -Name explorer -ErrorAction SilentlyContinue |
                Select-Object -First 1
        }
        while ($null -eq $ExplorerProcess -and (Get-Date) -lt $Deadline)
    }

    if ($null -eq $ExplorerProcess) {
        throw "Windows Explorer did not restart within $TimeoutSeconds seconds."
    }

    return [pscustomobject]@{
        PSTypeName = 'Hermes.ExplorerRestartResult'
        Requested = $true
        Restarted = $true
        ProcessId = $ExplorerProcess.Id
    }
}

#endregion Windows Explorer helper

#region Public exports

Export-ModuleMember -Function @(
    'Write-HermesLog'
    'Write-HermesSuccess'
    'Write-HermesWarning'
    'Write-HermesError'
    'Test-HermesAdministrator'
    'Test-HermesOperatingSystem'
    'Test-HermesPowerShell'
    'Test-HermesRegistryPath'
    'Get-HermesRegistryValue'
    'Set-HermesRegistryValue'
    'Remove-HermesRegistryValue'
    'Restart-HermesExplorer'
    'Export-HermesJson'
    'Import-HermesJson'
)

#endregion Public exports
