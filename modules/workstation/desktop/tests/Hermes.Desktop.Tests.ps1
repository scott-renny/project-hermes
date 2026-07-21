$discoveryManifest = Join-Path $PSScriptRoot '..\Hermes.Desktop.psd1'
Import-Module $discoveryManifest -Force -ErrorAction Stop

BeforeAll {
    $script:Manifest = Join-Path $PSScriptRoot '..\Hermes.Desktop.psd1'
    Remove-Module Hermes.Desktop -Force -ErrorAction SilentlyContinue
    Import-Module $script:Manifest -Force -ErrorAction Stop
    $script:DesktopProfilePath = Join-Path $PSScriptRoot '..\..\..\..\configs\windows\hermes-desktop-base.psd1'
}

AfterAll { Remove-Module Hermes.Desktop -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.Desktop module contract' {
    It 'has a valid module manifest' {
        { Test-ModuleManifest $script:Manifest -ErrorAction Stop } | Should -Not -Throw
    }

    It 'uses module version 0.5.0' {
        (Test-ModuleManifest $script:Manifest).Version.ToString() | Should -Be '0.5.0'
    }

    It 'exports exactly the expected commands' {
        $expected = @(
            'Backup-HermesDesktopSettings'
            'Get-HermesDesktopSettings'
            'Restore-HermesDesktopSettings'
            'Set-HermesDesktopSettings'
            'Test-HermesDesktopConfiguration'
            'Test-HermesDesktopSettings'
        )
        @(Get-Command -Module Hermes.Desktop).Name | Sort-Object | Should -Be ($expected | Sort-Object)
    }

    It 'provides help for every public command' {
        foreach ($command in Get-Command -Module Hermes.Desktop) {
            (Get-Help $command.Name).Synopsis | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes Desktop profile' {
    It 'exists as a PowerShell data file' {
        Test-Path -LiteralPath $script:DesktopProfilePath -PathType Leaf |
            Should -BeTrue
    }

    It 'contains a valid portable desktop configuration' {
        $configuration = Import-PowerShellDataFile -LiteralPath $script:DesktopProfilePath
        $result = Test-HermesDesktopConfiguration -Configuration $configuration

        $result.IsValid | Should -BeTrue
        $result.Configuration.Count | Should -Be 3
        [IO.Path]::IsPathFullyQualified($result.Configuration.WallpaperPath) |
            Should -BeTrue
    }
}

Describe 'Test-HermesDesktopConfiguration' {
    It 'accepts a complete configuration' {
        $file = Join-Path $TestDrive 'wallpaper.png'
        Set-Content -LiteralPath $file -Value 'test'
        $result = Test-HermesDesktopConfiguration -Configuration @{
            WallpaperPath = $file; WallpaperStyle = 'Fill'; DesktopIcons = 'Hidden'
        }
        $result.IsValid | Should -BeTrue
        $result.Configuration.Count | Should -Be 3
    }

    It 'accepts every wallpaper style' -ForEach @('Fill', 'Fit', 'Stretch', 'Center', 'Tile', 'Span') {
        (Test-HermesDesktopConfiguration -Configuration @{ WallpaperStyle = $_ }).IsValid | Should -BeTrue
    }

    It 'normalizes values case-insensitively' {
        $result = Test-HermesDesktopConfiguration -Configuration @{ WallpaperStyle = 'fill'; DesktopIcons = 'shown' }
        $result.Configuration.WallpaperStyle | Should -Be 'Fill'
        $result.Configuration.DesktopIcons | Should -Be 'Shown'
    }

    It 'rejects an empty configuration' {
        (Test-HermesDesktopConfiguration -Configuration @{}).IsValid | Should -BeFalse
    }

    It 'rejects unsupported settings' {
        (Test-HermesDesktopConfiguration -Configuration @{ Accent = 'Blue' }).IsValid | Should -BeFalse
    }

    It 'accepts a repository-relative wallpaper path' {
        $repositoryRoot = [IO.Path]::GetFullPath(
            (Join-Path $PSScriptRoot '..\..\..\..')
        )
        $relativeDirectory = 'assets\wallpapers'
        $relativePath = Join-Path $relativeDirectory 'desktop-test-wallpaper.png'
        $absoluteDirectory = Join-Path $repositoryRoot $relativeDirectory
        $absolutePath = Join-Path $repositoryRoot $relativePath

        New-Item -ItemType Directory -Path $absoluteDirectory -Force | Out-Null
        Set-Content -LiteralPath $absolutePath -Value 'test'

        try {
            $result = Test-HermesDesktopConfiguration -Configuration @{
                WallpaperPath = $relativePath
            }

            $result.IsValid | Should -BeTrue
            $result.Configuration.WallpaperPath | Should -Be $absolutePath
        }
        finally {
            Remove-Item -LiteralPath $absolutePath -Force -ErrorAction SilentlyContinue
        }
    }

    It 'rejects a missing wallpaper file' {
        $missing = Join-Path $TestDrive 'missing.png'
        (Test-HermesDesktopConfiguration -Configuration @{ WallpaperPath = $missing }).IsValid | Should -BeFalse
    }
}

InModuleScope Hermes.Desktop {
    Describe 'Get-HermesDesktopSettings' {
        BeforeEach { Mock Get-HermesRegistryValue }

        It 'maps native Registry values to the canonical model' {
            Mock Get-HermesRegistryValue {
                switch ($Name) {
                    'WallPaper' { 'C:\wallpaper.png' }
                    'WallpaperStyle' { '10' }
                    'TileWallpaper' { '0' }
                    'HideIcons' { 1 }
                }
            }
            $result = Get-HermesDesktopSettings
            $result.WallpaperPath | Should -Be 'C:\wallpaper.png'
            $result.WallpaperStyle | Should -Be 'Fill'
            $result.DesktopIcons | Should -Be 'Hidden'
        }

        It 'reports missing values as NotConfigured' {
            Mock Get-HermesRegistryValue { $DefaultValue }
            $result = Get-HermesDesktopSettings
            $result.WallpaperPath | Should -Be 'NotConfigured'
            $result.WallpaperStyle | Should -Be 'NotConfigured'
            $result.DesktopIcons | Should -Be 'NotConfigured'
        }
    }

    Describe 'Set-HermesDesktopSettings' {
        BeforeEach {
            Mock Get-HermesDesktopSettings { [pscustomobject]@{ WallpaperPath='C:\old.png'; WallpaperStyle='Fit'; DesktopIcons='Shown' } }
            Mock Backup-HermesDesktopSettings { [pscustomobject]@{ BackupPath='backup.json' } }
            Mock Set-HermesRegistryValue
            Mock Invoke-HermesDesktopRefresh
            Mock Restart-HermesExplorer
        }

        It 'supports WhatIf without backup or writes' {
            Set-HermesDesktopSettings -Configuration @{ WallpaperStyle='Fill' } -WhatIf
            Should -Invoke Backup-HermesDesktopSettings -Times 0
            Should -Invoke Set-HermesRegistryValue -Times 0
        }

        It 'maps wallpaper style to two Registry writes' {
            $script:complianceCall = 0
            Mock Test-HermesDesktopSettings {
                $script:complianceCall++
                [pscustomobject]@{
                    IsCompliant = ($script:complianceCall -gt 1)
                    Differences = if ($script:complianceCall -gt 1) { @() } else { @(1) }
                }
            }
            Set-HermesDesktopSettings -Configuration @{ WallpaperStyle='Fill' } -Confirm:$false | Out-Null
            Should -Invoke Set-HermesRegistryValue -Times 2
            Should -Invoke Invoke-HermesDesktopRefresh -Times 1
            Should -Invoke Test-HermesDesktopSettings -Times 2
        }

        It 'returns unchanged for compliant settings' {
            Mock Test-HermesDesktopSettings { [pscustomobject]@{ IsCompliant=$true; Differences=@() } }
            $result = Set-HermesDesktopSettings -Configuration @{ DesktopIcons='Shown' }
            $result.Changed | Should -BeFalse
            Should -Invoke Backup-HermesDesktopSettings -Times 0
        }
    }

    Describe 'Restore-HermesDesktopSettings' {
        It 'throws when the backup is missing' {
            Mock Read-HermesBackup { throw 'The backup file could not be found.' }
            { Restore-HermesDesktopSettings -BackupPath 'missing.json' -Confirm:$false } | Should -Throw
        }

        It 'rejects a backup without exact restore metadata' {
            Mock Read-HermesBackup { [pscustomobject]@{ Settings = [pscustomobject]@{} } }
            { Restore-HermesDesktopSettings -BackupPath 'legacy.json' -Confirm:$false } | Should -Throw '*restore metadata*'
        }
    }
}
