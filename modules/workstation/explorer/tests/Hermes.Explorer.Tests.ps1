$moduleManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\Hermes.Explorer.psd1'

Import-Module `
    -Name $moduleManifest `
    -Force `
    -ErrorAction Stop

$exportTestCases = @(
    @{ FunctionName = 'Get-HermesExplorerSettings' }
    @{ FunctionName = 'Test-HermesExplorerConfiguration' }
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
        It 'provides the shared backup writer inside Explorer scope' {
            Get-Command `
                -Name Write-HermesBackup `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'provides the shared backup reader inside Explorer scope' {
            Get-Command `
                -Name Read-HermesBackup `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Get-HermesExplorerSettings' {
        It 'maps registry values to Hermes settings' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 0
                    Hidden      = 1
                    LaunchTo    = 1
                }
            }

            $result = Get-HermesExplorerSettings

            $result.ShowFileExtensions |
                Should -BeTrue

            $result.ShowHiddenFiles |
                Should -BeTrue

            $result.LaunchExplorerTo |
                Should -Be 'ThisPC'
        }

        It 'maps disabled values correctly' {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    HideFileExt = 1
                    Hidden      = 2
                    LaunchTo    = 2
                }
            }

            $result = Get-HermesExplorerSettings

            $result.ShowFileExtensions |
                Should -BeFalse

            $result.ShowHiddenFiles |
                Should -BeFalse

            $result.LaunchExplorerTo |
                Should -Be 'Home'
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

    Describe 'Test-HermesExplorerConfiguration' {
        It 'accepts a valid configuration' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $false
                launchExplorerTo   = 'ThisPC'
            }

            $result = Test-HermesExplorerConfiguration `
                -Configuration $configuration

            $result.IsValid |
                Should -BeTrue

            $result.ErrorCount |
                Should -Be 0

            $result.NormalizedConfiguration.ShowFileExtensions |
                Should -BeTrue
        }

        It 'reports all missing required properties' {
            $result = Test-HermesExplorerConfiguration `
                -Configuration ([PSCustomObject]@{})

            $result.IsValid |
                Should -BeFalse

            $result.ErrorCount |
                Should -Be 3
        }

        It 'rejects non-Boolean file extension values' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = 'yes'
                showHiddenFiles    = $false
                launchExplorerTo   = 'ThisPC'
            }

            $result = Test-HermesExplorerConfiguration `
                -Configuration $configuration

            $result.IsValid |
                Should -BeFalse

            $result.Errors -join ' ' |
                Should -BeLike '*showFileExtensions*Boolean*'
        }

        It 'rejects non-Boolean hidden file values' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = 1
                launchExplorerTo   = 'ThisPC'
            }

            $result = Test-HermesExplorerConfiguration `
                -Configuration $configuration

            $result.IsValid |
                Should -BeFalse

            $result.Errors -join ' ' |
                Should -BeLike '*showHiddenFiles*Boolean*'
        }

        It 'rejects an unsupported Explorer destination' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $false
                launchExplorerTo   = 'Downloads'
            }

            $result = Test-HermesExplorerConfiguration `
                -Configuration $configuration

            $result.IsValid |
                Should -BeFalse

            $result.Errors -join ' ' |
                Should -BeLike "*'ThisPC' or 'Home'*"
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

        It 'creates a standardized backup through Hermes.Core' {
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
        }

        It 'throws for an invalid configuration' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = 'yes'
                showHiddenFiles    = $false
                launchExplorerTo   = 'ThisPC'
            }

            {
                Test-HermesExplorerSettings `
                    -Configuration $configuration
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*Invalid Explorer configuration*'
        }
    }

    Describe 'Set-HermesExplorerSettings' {
        BeforeEach {
            $script:readCount = 0

            Mock Get-HermesExplorerSettings {
                $script:readCount++

                if ($script:readCount -eq 1) {
                    return [PSCustomObject]@{
                        ShowFileExtensions = $false
                        ShowHiddenFiles    = $false
                        LaunchExplorerTo   = 'Home'
                    }
                }

                return [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $true
                    LaunchExplorerTo   = 'ThisPC'
                }
            }

            Mock Backup-HermesExplorerSettings {
                [PSCustomObject]@{
                    BackupPath = 'C:\Backups\Explorer.json'
                }
            }

            Mock Set-ItemProperty
        }

        It 'creates a backup before applying changes' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            $result = Set-HermesExplorerSettings `
                -Configuration $configuration `
                -Confirm:$false

            $result.BackupCreated |
                Should -BeTrue

            $result.BackupPath |
                Should -Be 'C:\Backups\Explorer.json'

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 1 `
                -Exactly
        }

        It 'writes the correct registry values' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            $null = Set-HermesExplorerSettings `
                -Configuration $configuration `
                -Confirm:$false

            Should -Invoke Set-ItemProperty `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'HideFileExt' -and
                    $Value -eq 0
                }

            Should -Invoke Set-ItemProperty `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'Hidden' -and
                    $Value -eq 1
                }

            Should -Invoke Set-ItemProperty `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'LaunchTo' -and
                    $Value -eq 1
                }
        }

        It 'returns a verified result after applying settings' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            $result = Set-HermesExplorerSettings `
                -Configuration $configuration `
                -Confirm:$false

            $result.Applied |
                Should -BeTrue

            $result.Verified |
                Should -BeTrue

            $result.RestartExplorerRequired |
                Should -BeTrue
        }

        It 'does not create a backup or write values with WhatIf' {
            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            $result = Set-HermesExplorerSettings `
                -Configuration $configuration `
                -WhatIf

            $result.Planned |
                Should -BeTrue

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 0 `
                -Exactly

            Should -Invoke Set-ItemProperty `
                -Times 0 `
                -Exactly
        }

        It 'does nothing when settings are already compliant' {
            Mock Get-HermesExplorerSettings {
                [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $true
                    LaunchExplorerTo   = 'ThisPC'
                }
            }

            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            $result = Set-HermesExplorerSettings `
                -Configuration $configuration `
                -Confirm:$false

            $result.Applied |
                Should -BeFalse

            $result.Verified |
                Should -BeTrue

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 0 `
                -Exactly

            Should -Invoke Set-ItemProperty `
                -Times 0 `
                -Exactly
        }

        It 'throws and includes the backup path when a registry write fails' {
            Mock Set-ItemProperty {
                throw 'Write denied'
            }

            $configuration = [PSCustomObject]@{
                showFileExtensions = $true
                showHiddenFiles    = $true
                launchExplorerTo   = 'ThisPC'
            }

            {
                Set-HermesExplorerSettings `
                    -Configuration $configuration `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*C:\Backups\Explorer.json*"
        }
    }

    Describe 'Restore-HermesExplorerSettings' {
        It 'is not implemented yet' {
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
