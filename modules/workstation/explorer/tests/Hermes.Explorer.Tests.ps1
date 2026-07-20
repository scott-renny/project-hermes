$moduleManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\Hermes.Explorer.psd1'

Import-Module `
    -Name $moduleManifest `
    -Force `
    -ErrorAction Stop

$exportTestCases = @(
    @{ FunctionName = 'Get-HermesExplorerSettings' }
    @{ FunctionName = 'Backup-HermesExplorerSettings' }
    @{ FunctionName = 'Test-HermesExplorerSettings' }
    @{ FunctionName = 'Set-HermesExplorerSettings' }
    @{ FunctionName = 'Restore-HermesExplorerSettings' }
)

AfterAll {
    Remove-Module `
        -Name Hermes.Explorer `
        -ErrorAction SilentlyContinue
}

Describe 'Hermes.Explorer module' {
    Context 'Module loading and exports' {
        It 'imports successfully' {
            Get-Module -Name Hermes.Explorer |
                Should -Not -BeNullOrEmpty
        }

        It 'exports <FunctionName>' -ForEach $exportTestCases {
            param(
                [string]$FunctionName
            )

            Get-Command `
                -Name $FunctionName `
                -Module Hermes.Explorer `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }
}

InModuleScope Hermes.Explorer {
    Describe 'Hermes.Core dependency' {
        It 'provides the shared backup command inside Explorer module scope' {
            Get-Command `
                -Name Write-HermesBackup `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'provides the shared backup reader inside Explorer module scope' {
            Get-Command `
                -Name Read-HermesBackup `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Get-HermesExplorerSettings' {
        It 'maps HideFileExt 0 to ShowFileExtensions true' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                    LaunchTo    = 1
                }
            }

            (Get-HermesExplorerSettings).ShowFileExtensions |
                Should -BeTrue
        }

        It 'maps HideFileExt 1 to ShowFileExtensions false' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 1
                    Hidden      = 2
                    LaunchTo    = 1
                }
            }

            (Get-HermesExplorerSettings).ShowFileExtensions |
                Should -BeFalse
        }

        It 'maps Hidden 1 to ShowHiddenFiles true' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 1
                    LaunchTo    = 1
                }
            }

            (Get-HermesExplorerSettings).ShowHiddenFiles |
                Should -BeTrue
        }

        It 'maps Hidden 2 to ShowHiddenFiles false' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                    LaunchTo    = 1
                }
            }

            (Get-HermesExplorerSettings).ShowHiddenFiles |
                Should -BeFalse
        }

        It 'maps LaunchTo 1 to ThisPC' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                    LaunchTo    = 1
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'ThisPC'
        }

        It 'maps LaunchTo 2 to Home' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                    LaunchTo    = 2
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'Home'
        }

        It 'returns Unknown for an unsupported LaunchTo value' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                    LaunchTo    = 99
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'Unknown'
        }

        It 'returns NotConfigured when LaunchTo is absent' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 2
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'NotConfigured'
        }

        It 'throws when the registry cannot be read' {
            Mock Get-ItemProperty {
                throw 'Registry unavailable'
            }

            {
                Get-HermesExplorerSettings
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*Unable to read Explorer settings*'
        }
    }

    Describe 'Backup-HermesExplorerSettings' {
        BeforeEach {
            Mock Get-HermesExplorerSettings {
                [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $false
                    LaunchExplorerTo   = 'ThisPC'
                }
            }
        }

        It 'creates a standardized Explorer backup through Hermes.Core' {
            $backupDirectory = Join-Path `
                -Path $TestDrive `
                -ChildPath 'explorer-backups'

            $result = Backup-HermesExplorerSettings `
                -BackupDirectory $backupDirectory

            Test-Path `
                -LiteralPath $result.BackupPath `
                -PathType Leaf |
                Should -BeTrue

            $document = Read-HermesBackup `
                -BackupPath $result.BackupPath `
                -ExpectedModuleName 'Explorer'

            $document.Settings.ShowFileExtensions |
                Should -BeTrue

            $document.Settings.ShowHiddenFiles |
                Should -BeFalse

            $document.Settings.LaunchExplorerTo |
                Should -Be 'ThisPC'
        }

        It 'returns Hermes.Core backup metadata' {
            $backupDirectory = Join-Path `
                -Path $TestDrive `
                -ChildPath 'metadata-backups'

            $result = Backup-HermesExplorerSettings `
                -BackupDirectory $backupDirectory

            $result.ModuleName |
                Should -Be 'Explorer'

            $result.BackupId |
                Should -Not -BeNullOrEmpty

            $result.CreatedAt |
                Should -BeOfType ([datetime])
        }
    }

    Describe 'Test-HermesExplorerSettings' {
        BeforeEach {
            Mock Get-HermesExplorerSettings {
                [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $false
                    LaunchExplorerTo   = 'ThisPC'
                }
            }
        }

        It 'reports compliant settings' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $false
                launchExplorerTo   = 'ThisPC'
            }

            $result = Test-HermesExplorerSettings `
                -Configuration $configuration

            $result.IsCompliant |
                Should -BeTrue

            $result.DifferenceCount |
                Should -Be 0
        }

        It 'reports each differing setting' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $false
                showHiddenFiles    = $true
                launchExplorerTo   = 'Home'
            }

            $result = Test-HermesExplorerSettings `
                -Configuration $configuration

            $result.IsCompliant |
                Should -BeFalse

            $result.DifferenceCount |
                Should -Be 3

            $result.Differences.Setting |
                Should -Contain 'ShowFileExtensions'

            $result.Differences.Setting |
                Should -Contain 'ShowHiddenFiles'

            $result.Differences.Setting |
                Should -Contain 'LaunchExplorerTo'
        }

        It 'rejects a missing showFileExtensions property' {
            $configuration = [PSCustomObject]@{
                showHiddenFiles  = $false
                launchExplorerTo = 'ThisPC'
            }

            {
                Test-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*showFileExtensions*"
        }

        It 'rejects a missing showHiddenFiles property' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                launchExplorerTo   = 'ThisPC'
            }

            {
                Test-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*showHiddenFiles*"
        }

        It 'rejects a missing launchExplorerTo property' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $false
            }

            {
                Test-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*launchExplorerTo*"
        }

        It 'rejects an unsupported launchExplorerTo value' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $false
                launchExplorerTo   = 'Downloads'
            }

            {
                Test-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*must be either 'ThisPC' or 'Home'*"
        }
    }

    Describe 'Unimplemented change functions' {
        It 'does not apply Explorer settings yet' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            {
                Set-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*has not been implemented yet*'
        }

        It 'does not restore Explorer settings yet' {
            {
                Restore-HermesExplorerSettings `
                    -BackupPath 'backup.json'
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*has not been implemented yet*'
        }
    }
}
