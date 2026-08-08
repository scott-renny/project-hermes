[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repositoryRoot 'assets\rainmeter'

$documents = [Environment]::GetFolderPath('MyDocuments')
$destinationRoot = Join-Path $documents 'Rainmeter\Skins'

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Hermes Rainmeter assets were not found at '$sourceRoot'."
}

$sharedTheme = Join-Path $sourceRoot '@Resources\HermesVisual.inc'
$skinNames = @(
    Get-ChildItem -LiteralPath $sourceRoot -Directory |
        Where-Object Name -ne '@Resources' |
        Where-Object {
            Get-ChildItem -LiteralPath $_.FullName -Filter '*.ini' -File
        } |
        Select-Object -ExpandProperty Name
)

if ($PSCmdlet.ShouldProcess($destinationRoot, 'Install Project Hermes Rainmeter skins')) {
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null

    foreach ($skinName in $skinNames) {
        $source = Join-Path $sourceRoot $skinName
        $destination = Join-Path $destinationRoot $skinName

        if (-not (Test-Path -LiteralPath $source -PathType Container)) {
            throw "Required Rainmeter asset '$source' is missing."
        }

        & robocopy.exe `
            $source `
            $destination `
            /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP |
            Out-Null

        if ($LASTEXITCODE -ge 8) {
            throw "Rainmeter deployment failed for '$skinName' with Robocopy exit code $LASTEXITCODE."
        }

        $installedIniFiles = Get-ChildItem -LiteralPath $destination -Filter '*.ini' -File
        foreach ($installedIni in $installedIniFiles) {
            $content = Get-Content -LiteralPath $installedIni.FullName -Raw

            if ($content -match '@Include=#@#HermesVisual\.inc') {
                & robocopy.exe `
                    (Split-Path -Parent $sharedTheme) `
                    $destination `
                    (Split-Path -Leaf $sharedTheme) `
                    /R:2 /W:1 /NFL /NDL /NJH /NJS /NP |
                    Out-Null

                if ($LASTEXITCODE -ge 8) {
                    throw "Theme deployment failed for '$skinName' with Robocopy exit code $LASTEXITCODE."
                }

                $content = $content.Replace(
                    '@Include=#@#HermesVisual.inc',
                    '@Include=#CURRENTPATH#HermesVisual.inc'
                )
                Set-Content -LiteralPath $installedIni.FullName -Value $content -Encoding utf8NoBOM
            }
        }
    }
}

$rainmeterCandidates = @(
    (Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe')
    (Join-Path ${env:ProgramFiles(x86)} 'Rainmeter\Rainmeter.exe')
)

$rainmeterProcess = Get-Process Rainmeter -ErrorAction SilentlyContinue |
    Select-Object -First 1

$rainmeterPath = if ($rainmeterProcess) {
    $rainmeterProcess.Path
}
else {
    $rainmeterCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
}

if (-not $rainmeterPath) {
    throw 'Rainmeter.exe could not be located. Start Rainmeter and run this installer again.'
}

if (-not $rainmeterProcess) {
    Start-Process -FilePath $rainmeterPath
    Start-Sleep -Seconds 2
}

& $rainmeterPath '!RefreshApp'
Start-Sleep -Milliseconds 750

$configs = @(
    @{ Name = 'HermesLauncher'; File = 'HermesLauncher.ini' }
    @{ Name = 'HermesClock'; File = 'HermesClock.ini' }
    @{ Name = 'HermesPerformance'; File = 'HermesPerformance.ini' }
    @{ Name = 'HermesAgenda'; File = 'HermesAgenda.ini' }
    @{ Name = 'HermesNotes'; File = 'HermesNotes.ini' }
    @{ Name = 'HermesIdentity'; File = 'HermesIdentity.ini' }
)

foreach ($config in $configs) {
    & $rainmeterPath '!ActivateConfig' $config.Name $config.File
}

[pscustomobject]@{
    InstalledTo = $destinationRoot
    Rainmeter    = $rainmeterPath
    Skins        = $configs.Name
    Result       = 'Installed, refreshed, and loaded'
}
