Set-StrictMode -Version Latest

function Get-HermesRepositoryRoot {
    <#
    .SYNOPSIS
        Returns the Project Hermes repository root.

    .DESCRIPTION
        Resolves the repository root relative to the Hermes.Core module
        location. Hermes.Core is expected at:

        modules\core\Hermes.Core.psm1

    .OUTPUTS
        System.String
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        return [System.IO.Path]::GetFullPath(
            (Join-Path -Path $PSScriptRoot -ChildPath '..\..')
        )
    }
    catch {
        throw "Unable to resolve the Project Hermes repository root. $($_.Exception.Message)"
    }
}

function Get-HermesVersion {
    <#
    .SYNOPSIS
        Returns the version of the executing Hermes.Core module.

    .DESCRIPTION
        Uses the current module execution context rather than searching the
        caller's session. This works whether Hermes.Core is imported directly
        or as a nested dependency of another Hermes module.

    .OUTPUTS
        System.String
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $currentModule = $ExecutionContext.SessionState.Module

    if ($null -eq $currentModule) {
        throw 'Unable to determine the Hermes.Core module version.'
    }

    return $currentModule.Version.ToString()
}

function New-HermesGuid {
    <#
    .SYNOPSIS
        Creates a new Hermes identifier.

    .OUTPUTS
        System.String
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

    return [guid]::NewGuid().ToString()
}

function Write-HermesBackup {
    <#
    .SYNOPSIS
        Writes a standardized Hermes JSON backup.

    .DESCRIPTION
        Creates a timestamped UTF-8 JSON backup containing shared metadata
        and a module-specific settings payload.

    .PARAMETER ModuleName
        Logical name of the Hermes module creating the backup.

    .PARAMETER Settings
        Object containing the settings to preserve.

    .PARAMETER BackupDirectory
        Optional destination directory. When omitted, the backup is written
        to exports\backups\<module-name> beneath the repository root.

    .PARAMETER AdditionalMetadata
        Optional hashtable of extra metadata to include in the document.

    .OUTPUTS
        PSCustomObject describing the backup that was created.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Settings,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BackupDirectory,

        [Parameter()]
        [hashtable]$AdditionalMetadata
    )

    $normalizedModuleName = $ModuleName.Trim()

    if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
        $repositoryRoot = Get-HermesRepositoryRoot
        $folderName = $normalizedModuleName.ToLowerInvariant()

        $BackupDirectory = Join-Path `
            -Path $repositoryRoot `
            -ChildPath "exports\backups\$folderName"
    }
    else {
        $BackupDirectory = [System.IO.Path]::GetFullPath($BackupDirectory)
    }

    try {
        if (-not (Test-Path -LiteralPath $BackupDirectory)) {
            $null = New-Item `
                -Path $BackupDirectory `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop
        }
    }
    catch {
        throw "Unable to create backup directory '$BackupDirectory'. $($_.Exception.Message)"
    }

    $createdAt = Get-Date
    $backupId = New-HermesGuid
    $timestamp = $createdAt.ToString('yyyyMMdd-HHmmss-fff')
    $safeModuleName = $normalizedModuleName -replace '[^A-Za-z0-9._-]', '-'
    $backupFileName = "Hermes.$safeModuleName-$timestamp.json"

    $backupPath = Join-Path `
        -Path $BackupDirectory `
        -ChildPath $backupFileName

    $document = [ordered]@{
        SchemaVersion = '1.0'
        ModuleName    = $normalizedModuleName
        BackupId      = $backupId
        CreatedAt     = $createdAt.ToString('o')
        ComputerName  = $env:COMPUTERNAME
        UserName      = $env:USERNAME
        HermesVersion = Get-HermesVersion
        Settings      = $Settings
    }

    if ($null -ne $AdditionalMetadata) {
        $document.Add('AdditionalMetadata', $AdditionalMetadata)
    }

    try {
        $json = $document | ConvertTo-Json -Depth 20
        $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

        [System.IO.File]::WriteAllText(
            $backupPath,
            $json,
            $utf8WithoutBom
        )
    }
    catch {
        throw "Unable to save backup to '$backupPath'. $($_.Exception.Message)"
    }

    [PSCustomObject]@{
        BackupId        = $backupId
        ModuleName      = $normalizedModuleName
        BackupPath      = $backupPath
        BackupDirectory = $BackupDirectory
        CreatedAt       = $createdAt
        Settings        = $Settings
    }
}

function Read-HermesBackup {
    <#
    .SYNOPSIS
        Reads and validates a Hermes JSON backup.

    .PARAMETER BackupPath
        Path to the Hermes backup file.

    .PARAMETER ExpectedModuleName
        Optional module name that the backup must match.

    .OUTPUTS
        PSCustomObject containing the parsed backup document.
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedModuleName
    )

    $resolvedPath = try {
        (Resolve-Path -LiteralPath $BackupPath -ErrorAction Stop).Path
    }
    catch {
        throw "The backup file '$BackupPath' could not be found."
    }

    try {
        $document = Get-Content `
            -LiteralPath $resolvedPath `
            -Raw `
            -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Unable to read Hermes backup '$resolvedPath'. $($_.Exception.Message)"
    }

    $requiredProperties = @(
        'SchemaVersion'
        'ModuleName'
        'BackupId'
        'CreatedAt'
        'Settings'
    )

    foreach ($requiredProperty in $requiredProperties) {
        if ($document.PSObject.Properties.Name -notcontains $requiredProperty) {
            throw "The backup file is missing the required property '$requiredProperty'."
        }
    }

    if ($document.SchemaVersion -ne '1.0') {
        throw "Unsupported Hermes backup schema version '$($document.SchemaVersion)'."
    }

    if (
        -not [string]::IsNullOrWhiteSpace($ExpectedModuleName) -and
        $document.ModuleName -ne $ExpectedModuleName
    ) {
        throw "The backup belongs to module '$($document.ModuleName)', not '$ExpectedModuleName'."
    }

    return $document
}

Export-ModuleMember -Function @(
    'Get-HermesRepositoryRoot'
    'Get-HermesVersion'
    'New-HermesGuid'
    'Write-HermesBackup'
    'Read-HermesBackup'
)
