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

    Describe 'Hermes.Common dependency' {
        It 'provides the shared Registry reader inside Explorer scope' {
            Get-Command `
                -Name Get-HermesRegistryValue `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'provides the shared Registry writer inside Explorer scope' {
            Get-Command `
                -Name Set-HermesRegistryValue `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'provides the shared Registry removal helper inside Explorer scope' {
            Get-Command `
                -Name Remove-HermesRegistryValue `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }

    Describe 'Get-HermesExplorerSettings' {
        It 'maps registry values to Hermes settings' {
            Mock Get-HermesRegistryValue {
                switch ($Name) {
                    'HideFileExt' { 0 }
                    'Hidden' { 1 }
                    'LaunchTo' { 1 }
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
            Mock Get-HermesRegistryValue {
                switch ($Name) {
                    'HideFileExt' { 1 }
                    'Hidden' { 2 }
                    'LaunchTo' { 2 }
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
            Mock Get-HermesRegistryValue {
                switch ($Name) {
                    'HideFileExt' { 0 }
                    'Hidden' { 2 }
                    'LaunchTo' { $DefaultValue }
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'NotConfigured'
        }

        It 'returns Unknown for an unsupported LaunchTo value' {
            Mock Get-HermesRegistryValue {
                switch ($Name) {
                    'HideFileExt' { 0 }
                    'Hidden' { 2 }
                    'LaunchTo' { 99 }
                }
            }

            (Get-HermesExplorerSettings).LaunchExplorerTo |
                Should -Be 'Unknown'
        }

        It 'throws when the registry cannot be read' {
            Mock Get-HermesRegistryValue {
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

        It 'accepts a PowerShell data-file dictionary' {
            $configuration = @{
                showFileExtensions = $true
                showHiddenFiles    = $false
                launchExplorerTo   = 'ThisPC'
            }

            $result = Test-HermesExplorerConfiguration `
                -Configuration $configuration

            $result.IsValid |
                Should -BeTrue

            $result.NormalizedConfiguration.LaunchExplorerTo |
                Should -Be 'ThisPC'
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

            Mock Set-HermesRegistryValue
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

            Should -Invoke Set-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'HideFileExt' -and
                    $Value -eq 0
                }

            Should -Invoke Set-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'Hidden' -and
                    $Value -eq 1
                }

            Should -Invoke Set-HermesRegistryValue `
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

            Should -Invoke Set-HermesRegistryValue `
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

            Should -Invoke Set-HermesRegistryValue `
                -Times 0 `
                -Exactly
        }

        It 'throws and includes the backup path when a registry write fails' {
            Mock Set-HermesRegistryValue {
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
        BeforeEach {
            $script:restoreReadCount = 0
            $script:validRestoreBackupPath = Join-Path `
                -Path $TestDrive `
                -ChildPath 'explorer-restore.json'

            '{}' | Set-Content `
                -LiteralPath $script:validRestoreBackupPath `
                -Encoding UTF8

            Mock Read-HermesBackup {
                [PSCustomObject]@{
                    ModuleName = 'Explorer'
                    Settings   = [PSCustomObject]@{
                        ShowFileExtensions = $true
                        ShowHiddenFiles    = $true
                        LaunchExplorerTo   = 'ThisPC'
                    }
                }
            }

            Mock Backup-HermesExplorerSettings {
                [PSCustomObject]@{
                    BackupPath = 'C:\Backups\Explorer-Safety.json'
                }
            }

            Mock Set-HermesRegistryValue
            Mock Remove-HermesRegistryValue

            Mock Get-HermesExplorerSettings {
                $script:restoreReadCount++

                if ($script:restoreReadCount -eq 1) {
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
        }

        It 'throws when the backup file does not exist' {
            {
                Restore-HermesExplorerSettings `
                    -BackupPath (Join-Path $TestDrive 'missing.json') `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*Explorer backup could not be found*'
        }

        It 'rejects a backup created by another Hermes module' {
            Mock Read-HermesBackup {
                [PSCustomObject]@{
                    ModuleName = 'Terminal'
                    Settings   = [PSCustomObject]@{
                        ShowFileExtensions = $true
                        ShowHiddenFiles    = $true
                        LaunchExplorerTo   = 'ThisPC'
                    }
                }
            }

            {
                Restore-HermesExplorerSettings `
                    -BackupPath $script:validRestoreBackupPath `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*belongs to module*not Explorer*'
        }

        It 'rejects a backup with an invalid Explorer setting' {
            Mock Read-HermesBackup {
                [PSCustomObject]@{
                    ModuleName = 'Explorer'
                    Settings   = [PSCustomObject]@{
                        ShowFileExtensions = $true
                        ShowHiddenFiles    = $true
                        LaunchExplorerTo   = 'Downloads'
                    }
                }
            }

            {
                Restore-HermesExplorerSettings `
                    -BackupPath $script:validRestoreBackupPath `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*invalid LaunchExplorerTo value*'
        }

        It 'does nothing when the backup state is already restored' {
            Mock Get-HermesExplorerSettings {
                [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $true
                    LaunchExplorerTo   = 'ThisPC'
                }
            }

            $result = Restore-HermesExplorerSettings `
                -BackupPath $script:validRestoreBackupPath `
                -Confirm:$false

            $result.Restored |
                Should -BeFalse

            $result.Verified |
                Should -BeTrue

            $result.SafetyBackupCreated |
                Should -BeFalse

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 0 `
                -Exactly

            Should -Invoke Set-HermesRegistryValue `
                -Times 0 `
                -Exactly
        }

        It 'previews the restore without creating a backup or writing registry values' {
            $result = Restore-HermesExplorerSettings `
                -BackupPath $script:validRestoreBackupPath `
                -WhatIf

            $result.Restored |
                Should -BeFalse

            $result.Planned |
                Should -BeTrue

            $result.Verified |
                Should -BeFalse

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 0 `
                -Exactly

            Should -Invoke Set-HermesRegistryValue `
                -Times 0 `
                -Exactly

            Should -Invoke Remove-HermesRegistryValue `
                -Times 0 `
                -Exactly
        }

        It 'creates a safety backup and restores the saved registry values' {
            $result = Restore-HermesExplorerSettings `
                -BackupPath $script:validRestoreBackupPath `
                -Confirm:$false

            $result.Restored |
                Should -BeTrue

            $result.Verified |
                Should -BeTrue

            $result.SafetyBackupCreated |
                Should -BeTrue

            $result.SafetyBackupPath |
                Should -Be 'C:\Backups\Explorer-Safety.json'

            $result.RestartExplorerRequired |
                Should -BeTrue

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 1 `
                -Exactly

            Should -Invoke Set-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'HideFileExt' -and
                    $Value -eq 0
                }

            Should -Invoke Set-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'Hidden' -and
                    $Value -eq 1
                }

            Should -Invoke Set-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'LaunchTo' -and
                    $Value -eq 1
                }
        }

        It 'removes LaunchTo when the backup records NotConfigured' {
            Mock Read-HermesBackup {
                [PSCustomObject]@{
                    ModuleName = 'Explorer'
                    Settings   = [PSCustomObject]@{
                        ShowFileExtensions = $true
                        ShowHiddenFiles    = $true
                        LaunchExplorerTo   = 'NotConfigured'
                    }
                }
            }

            Mock Get-HermesExplorerSettings {
                $script:restoreReadCount++

                if ($script:restoreReadCount -eq 1) {
                    return [PSCustomObject]@{
                        ShowFileExtensions = $false
                        ShowHiddenFiles    = $false
                        LaunchExplorerTo   = 'Home'
                    }
                }

                return [PSCustomObject]@{
                    ShowFileExtensions = $true
                    ShowHiddenFiles    = $true
                    LaunchExplorerTo   = 'NotConfigured'
                }
            }

            $result = Restore-HermesExplorerSettings `
                -BackupPath $script:validRestoreBackupPath `
                -Confirm:$false

            $result.Verified |
                Should -BeTrue

            Should -Invoke Remove-HermesRegistryValue `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'LaunchTo'
                }

            Should -Invoke Set-HermesRegistryValue `
                -Times 0 `
                -Exactly `
                -ParameterFilter {
                    $Name -eq 'LaunchTo'
                }
        }

        It 'passes the requested safety backup directory to the backup operation' {
            $safetyDirectory = Join-Path `
                -Path $TestDrive `
                -ChildPath 'safety-backups'

            $null = Restore-HermesExplorerSettings `
                -BackupPath $script:validRestoreBackupPath `
                -SafetyBackupDirectory $safetyDirectory `
                -Confirm:$false

            Should -Invoke Backup-HermesExplorerSettings `
                -Times 1 `
                -Exactly `
                -ParameterFilter {
                    $BackupDirectory -eq $safetyDirectory
                }
        }

        It 'throws with the safety backup path when a registry write fails' {
            Mock Set-HermesRegistryValue {
                throw 'Write denied'
            }

            {
                Restore-HermesExplorerSettings `
                    -BackupPath $script:validRestoreBackupPath `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*C:\Backups\Explorer-Safety.json*'
        }

        It 'throws when post-restore verification fails' {
            Mock Get-HermesExplorerSettings {
                [PSCustomObject]@{
                    ShowFileExtensions = $false
                    ShowHiddenFiles    = $false
                    LaunchExplorerTo   = 'Home'
                }
            }

            {
                Restore-HermesExplorerSettings `
                    -BackupPath $script:validRestoreBackupPath `
                    -Confirm:$false
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*verification failed*C:\Backups\Explorer-Safety.json*'
        }
    }
}
