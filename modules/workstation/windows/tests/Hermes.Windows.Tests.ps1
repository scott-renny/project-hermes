$discoveryManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\Hermes.Windows.psd1'

Import-Module `
    -Name $discoveryManifest `
    -Force `
    -ErrorAction Stop

BeforeAll {
    $script:ModuleManifest = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath '..\Hermes.Windows.psd1'

    Remove-Module Hermes.Windows -Force -ErrorAction SilentlyContinue
    Import-Module $script:ModuleManifest -Force -ErrorAction Stop

    $script:VisualProfilePath = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath '..\..\..\..\configs\windows\hermes-visual-base.psd1'
}

AfterAll {
    Remove-Module Hermes.Windows -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Windows module contract' {
    It 'has a valid module manifest' {
        { Test-ModuleManifest $script:ModuleManifest -ErrorAction Stop } |
            Should -Not -Throw
    }

    It 'uses module version 0.5.0' {
        (Test-ModuleManifest $script:ModuleManifest).Version.ToString() |
            Should -Be '0.5.0'
    }

    It 'imports successfully' {
        Get-Module Hermes.Windows | Should -Not -BeNullOrEmpty
    }

    It 'exports exactly the expected commands' {
        $expected = @(
            'Backup-HermesWindowsSettings'
            'Get-HermesWindowsSettings'
            'Restore-HermesWindowsSettings'
            'Set-HermesWindowsSettings'
            'Test-HermesWindowsConfiguration'
            'Test-HermesWindowsSettings'
        )

        @(Get-Command -Module Hermes.Windows).Name |
            Sort-Object |
            Should -Be ($expected | Sort-Object)
    }

    It 'provides help for every public command' {
        foreach ($command in Get-Command -Module Hermes.Windows) {
            (Get-Help $command.Name).Synopsis |
                Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes Windows visual profile' {
    It 'exists as a PowerShell data file' {
        Test-Path `
            -LiteralPath $script:VisualProfilePath `
            -PathType Leaf |
            Should -BeTrue
    }

    It 'contains a valid Hermes.Windows configuration' {
        $configuration = Import-PowerShellDataFile `
            -LiteralPath $script:VisualProfilePath

        $result = Test-HermesWindowsConfiguration `
            -Configuration $configuration

        $result.IsValid | Should -BeTrue
        $result.Configuration.Count | Should -Be 4
    }
}

InModuleScope Hermes.Windows {
    Describe 'shared dependencies' {
        It 'imports Core backup commands' {
            Get-Command Write-HermesBackup -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command Read-HermesBackup -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'imports Common Registry commands' {
            Get-Command Get-HermesRegistryValue -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command Set-HermesRegistryValue -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command Remove-HermesRegistryValue -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Test-HermesWindowsConfiguration' {
        It 'accepts the complete canonical configuration' {
            $result = Test-HermesWindowsConfiguration -Configuration @{
                AppTheme         = 'Dark'
                SystemTheme      = 'Light'
                Transparency     = 'Enabled'
                AccentOnTitleBars = 'Disabled'
            }

            $result.IsValid | Should -BeTrue
            $result.Configuration.Count | Should -Be 4
        }

        It 'accepts a partial configuration' {
            $result = Test-HermesWindowsConfiguration -Configuration @{
                AppTheme = 'Dark'
            }

            $result.IsValid | Should -BeTrue
            $result.Configuration.AppTheme | Should -Be 'Dark'
        }

        It 'normalizes supported values case-insensitively' {
            $result = Test-HermesWindowsConfiguration -Configuration @{
                AppTheme = 'dark'
                Transparency = 'enabled'
            }

            $result.Configuration.AppTheme | Should -Be 'Dark'
            $result.Configuration.Transparency | Should -Be 'Enabled'
        }

        It 'rejects an empty configuration' {
            (Test-HermesWindowsConfiguration -Configuration @{}).IsValid |
                Should -BeFalse
        }

        It 'rejects unsupported properties' {
            $result = Test-HermesWindowsConfiguration -Configuration @{
                Wallpaper = 'example.jpg'
            }

            $result.IsValid | Should -BeFalse
            $result.Errors -join ' ' | Should -BeLike '*Unsupported*Wallpaper*'
        }

        It 'rejects invalid theme values' {
            (Test-HermesWindowsConfiguration -Configuration @{
                AppTheme = 'Blue'
            }).IsValid | Should -BeFalse
        }

        It 'rejects invalid state values' {
            (Test-HermesWindowsConfiguration -Configuration @{
                Transparency = 'Automatic'
            }).IsValid | Should -BeFalse
        }
    }

    Describe 'Get-HermesWindowsSettings' {
        It 'maps supported Registry values to the canonical model' {
            Mock Get-HermesWindowsRegistryState {
                switch ($Name) {
                    'AppsUseLightTheme' { [pscustomobject]@{ Exists = $true; Value = 0 } }
                    'SystemUsesLightTheme' { [pscustomobject]@{ Exists = $true; Value = 1 } }
                    'EnableTransparency' { [pscustomobject]@{ Exists = $true; Value = 1 } }
                    'ColorPrevalence' { [pscustomobject]@{ Exists = $true; Value = 0 } }
                }
            }

            $result = Get-HermesWindowsSettings
            $result.AppTheme | Should -Be 'Dark'
            $result.SystemTheme | Should -Be 'Light'
            $result.Transparency | Should -Be 'Enabled'
            $result.AccentOnTitleBars | Should -Be 'Disabled'
        }

        It 'reports absent values as NotConfigured' {
            Mock Get-HermesWindowsRegistryState {
                [pscustomobject]@{ Exists = $false; Value = $null }
            }

            $result = Get-HermesWindowsSettings
            $result.AppTheme | Should -Be 'NotConfigured'
            $result.SystemTheme | Should -Be 'NotConfigured'
            $result.Transparency | Should -Be 'NotConfigured'
            $result.AccentOnTitleBars | Should -Be 'NotConfigured'
        }

        It 'reports unsupported values as Unknown' {
            Mock Get-HermesWindowsRegistryState {
                [pscustomobject]@{ Exists = $true; Value = 99 }
            }

            $result = Get-HermesWindowsSettings
            $result.AppTheme | Should -Be 'Unknown'
            $result.Transparency | Should -Be 'Unknown'
        }

        It 'adds setting context to read failures' {
            Mock Get-HermesWindowsRegistryState { throw 'Registry unavailable' }

            { Get-HermesWindowsSettings } |
                Should -Throw '*Unable to read Windows setting*'
        }
    }

    Describe 'Test-HermesWindowsSettings' {
        BeforeEach {
            Mock Get-HermesWindowsSettings {
                [pscustomobject]@{
                    AppTheme          = 'Dark'
                    SystemTheme       = 'Dark'
                    Transparency      = 'Enabled'
                    AccentOnTitleBars = 'Disabled'
                }
            }
        }

        It 'reports compliance for matching selected values' {
            $result = Test-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
                Transparency = 'Enabled'
            }

            $result.IsCompliant | Should -BeTrue
            @($result.Differences).Count | Should -Be 0
        }

        It 'reports precise differences' {
            $result = Test-HermesWindowsSettings -Configuration @{
                AppTheme = 'Light'
            }

            $result.IsCompliant | Should -BeFalse
            @($result.Differences).Count | Should -Be 1
            $result.Differences[0].Setting | Should -Be 'AppTheme'
            $result.Differences[0].Actual | Should -Be 'Dark'
            $result.Differences[0].Expected | Should -Be 'Light'
        }

        It 'throws for invalid desired state' {
            { Test-HermesWindowsSettings -Configuration @{ AppTheme = 'Blue' } } |
                Should -Throw
        }
    }

    Describe 'Backup-HermesWindowsSettings' {
        BeforeEach {
            Mock Get-HermesWindowsSettings {
                [pscustomobject]@{
                    AppTheme = 'Dark'; SystemTheme = 'Dark'
                    Transparency = 'Enabled'; AccentOnTitleBars = 'Disabled'
                }
            }
            Mock Get-HermesWindowsRegistryState {
                [pscustomobject]@{ Exists = $true; Value = 1 }
            }
            Mock Write-HermesBackup {
                [pscustomobject]@{ BackupPath = 'windows.json' }
            }
        }

        It 'writes standardized settings and exact Registry metadata' {
            $result = Backup-HermesWindowsSettings
            $result.BackupPath | Should -Be 'windows.json'

            Should -Invoke Write-HermesBackup -Times 1 -Exactly -ParameterFilter {
                $ModuleName -eq 'Hermes.Windows' -and
                $AdditionalMetadata.WindowsBackupFormat -eq '1.0' -and
                $AdditionalMetadata.Registry.Count -eq 4
            }
        }

        It 'passes a custom backup directory to Core' {
            Backup-HermesWindowsSettings -BackupDirectory 'C:\Backups' | Out-Null
            Should -Invoke Write-HermesBackup -Times 1 -Exactly -ParameterFilter {
                $BackupDirectory -eq 'C:\Backups'
            }
        }
    }

    Describe 'Set-HermesWindowsSettings' {
        BeforeEach {
            $script:settingsRead = 0
            Mock Get-HermesWindowsSettings {
                $script:settingsRead++
                if ($script:settingsRead -le 2) {
                    return [pscustomobject]@{
                        AppTheme = 'Light'; SystemTheme = 'Light'
                        Transparency = 'Disabled'; AccentOnTitleBars = 'Disabled'
                    }
                }
                [pscustomobject]@{
                    AppTheme = 'Dark'; SystemTheme = 'Light'
                    Transparency = 'Enabled'; AccentOnTitleBars = 'Disabled'
                }
            }
            Mock Backup-HermesWindowsSettings {
                [pscustomobject]@{ BackupPath = 'windows.json' }
            }
            Mock Set-HermesRegistryValue
            Mock Restart-HermesExplorer
        }

        It 'supports WhatIf without backup or Registry writes' {
            Set-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
            } -WhatIf

            Should -Invoke Backup-HermesWindowsSettings -Times 0
            Should -Invoke Set-HermesRegistryValue -Times 0
        }

        It 'creates a backup and maps selected values' {
            $result = Set-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
                Transparency = 'Enabled'
            } -Confirm:$false

            $result.Changed | Should -BeTrue
            Should -Invoke Backup-HermesWindowsSettings -Times 1
            Should -Invoke Set-HermesRegistryValue -Times 1 -ParameterFilter {
                $Name -eq 'AppsUseLightTheme' -and $Value -eq 0
            }
            Should -Invoke Set-HermesRegistryValue -Times 1 -ParameterFilter {
                $Name -eq 'EnableTransparency' -and $Value -eq 1
            }
        }

        It 'skips the backup when requested' {
            Set-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
            } -SkipBackup -Confirm:$false | Out-Null
            Should -Invoke Backup-HermesWindowsSettings -Times 0
        }

        It 'restarts Explorer only when requested' {
            $result = Set-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
            } -RestartExplorer -Confirm:$false
            $result.ExplorerRestarted | Should -BeTrue
            Should -Invoke Restart-HermesExplorer -Times 1
        }

        It 'throws with recovery context when a write fails' {
            Mock Set-HermesRegistryValue { throw 'Write denied' }
            { Set-HermesWindowsSettings -Configuration @{
                AppTheme = 'Dark'
            } -Confirm:$false } | Should -Throw '*windows.json*'
        }
    }

    Describe 'Restore-HermesWindowsSettings' {
        BeforeEach {
            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{
                        AppTheme = 'Dark'; SystemTheme = 'Light'
                        Transparency = 'Enabled'; AccentOnTitleBars = 'NotConfigured'
                    }
                    AdditionalMetadata = [pscustomobject]@{
                        Registry = [pscustomobject]@{
                            AppTheme = [pscustomobject]@{ Exists = $true; Value = 0 }
                            SystemTheme = [pscustomobject]@{ Exists = $true; Value = 1 }
                            Transparency = [pscustomobject]@{ Exists = $true; Value = 1 }
                            AccentOnTitleBars = [pscustomobject]@{ Exists = $false; Value = $null }
                        }
                    }
                }
            }
            Mock Get-HermesWindowsSettings {
                [pscustomobject]@{
                    AppTheme = 'Light'; SystemTheme = 'Light'
                    Transparency = 'Disabled'; AccentOnTitleBars = 'Enabled'
                }
            }
            $script:rawRead = 0
            Mock Get-HermesWindowsRegistryState {
                $script:rawRead++
                if ($script:rawRead -le 4) {
                    return [pscustomobject]@{ Exists = $true; Value = 99 }
                }
                switch ($Name) {
                    'AppsUseLightTheme' { [pscustomobject]@{ Exists = $true; Value = 0 } }
                    'SystemUsesLightTheme' { [pscustomobject]@{ Exists = $true; Value = 1 } }
                    'EnableTransparency' { [pscustomobject]@{ Exists = $true; Value = 1 } }
                    'ColorPrevalence' { [pscustomobject]@{ Exists = $false; Value = $null } }
                }
            }
            Mock Set-HermesRegistryValue
            Mock Remove-HermesRegistryValue
            Mock Backup-HermesWindowsSettings {
                [pscustomobject]@{ BackupPath = 'safety.json' }
            }
            Mock Restart-HermesExplorer
        }

        It 'supports WhatIf without writes' {
            Restore-HermesWindowsSettings -BackupPath 'windows.json' -WhatIf
            Should -Invoke Set-HermesRegistryValue -Times 0
            Should -Invoke Remove-HermesRegistryValue -Times 0
        }

        It 'restores exact existing and absent Registry states' {
            $result = Restore-HermesWindowsSettings `
                -BackupPath 'windows.json' `
                -Confirm:$false

            $result.Changed | Should -BeTrue
            $result.Verified | Should -BeTrue
            Should -Invoke Set-HermesRegistryValue -Times 3
            Should -Invoke Remove-HermesRegistryValue -Times 1 -ParameterFilter {
                $Name -eq 'ColorPrevalence'
            }
        }

        It 'creates an optional safety backup' {
            Restore-HermesWindowsSettings `
                -BackupPath 'windows.json' `
                -CreateSafetyBackup `
                -Confirm:$false | Out-Null
            Should -Invoke Backup-HermesWindowsSettings -Times 1
        }

        It 'rejects backups with no restorable state' {
            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{
                        AppTheme = 'Unknown'; SystemTheme = 'Unknown'
                        Transparency = 'Unknown'; AccentOnTitleBars = 'Unknown'
                    }
                }
            }

            { Restore-HermesWindowsSettings -BackupPath 'empty.json' -Confirm:$false } |
                Should -Throw '*no restorable Windows settings*'
        }
    }
}
