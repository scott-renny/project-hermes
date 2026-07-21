BeforeAll {
    $script:ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $script:ManifestPath = Join-Path $script:ModuleRoot 'Hermes.Taskbar.psd1'
    $script:TaskbarProfilePath = Join-Path `
        -Path $PSScriptRoot `
        -ChildPath '..\..\..\..\configs\windows\hermes-taskbar-base.psd1'
    $script:ExpectedCommands = @(
        'Backup-HermesTaskbarSettings'
        'Get-HermesTaskbarSettings'
        'Restore-HermesTaskbarSettings'
        'Set-HermesTaskbarSettings'
        'Test-HermesTaskbarConfiguration'
        'Test-HermesTaskbarSettings'
    )

    Remove-Module Hermes.Taskbar -Force -ErrorAction SilentlyContinue
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Hermes.Taskbar -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Taskbar module contract' {
    It 'has a valid module manifest' {
        {
            Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'uses module version 0.5.0' {
        (Test-ModuleManifest -Path $script:ManifestPath).Version |
            Should -Be ([version]'0.5.0')
    }

    It 'imports successfully' {
        Get-Module Hermes.Taskbar | Should -Not -BeNullOrEmpty
    }

    It 'exports exactly the expected public commands' {
        $Actual = @(
            Get-Command -Module Hermes.Taskbar |
                Select-Object -ExpandProperty Name |
                Sort-Object
        )
        $Expected = @($script:ExpectedCommands | Sort-Object)

        $Actual.Count | Should -Be $Expected.Count
        Compare-Object -ReferenceObject $Expected -DifferenceObject $Actual |
            Should -BeNullOrEmpty
    }

    It 'provides comment-based help for every public command' {
        foreach ($CommandName in $script:ExpectedCommands) {
            (Get-Help -Name $CommandName -ErrorAction Stop).Synopsis |
                Should -Not -BeNullOrEmpty -Because "$CommandName requires help"
        }
    }
}

Describe 'Hermes Taskbar profile' {
    It 'exists as a PowerShell data file' {
        Test-Path `
            -LiteralPath $script:TaskbarProfilePath `
            -PathType Leaf |
            Should -BeTrue
    }

    It 'contains a valid Windows Home Taskbar configuration' {
        $configuration = Import-PowerShellDataFile `
            -LiteralPath $script:TaskbarProfilePath

        $result = Test-HermesTaskbarConfiguration `
            -Configuration $configuration

        $result.IsValid | Should -BeTrue
        @($result.Errors).Count | Should -Be 0
        $result.Configuration.Count | Should -Be 6
    }
}

Describe 'Test-HermesTaskbarConfiguration' {
    It 'accepts the complete canonical configuration model' {
        $Result = Test-HermesTaskbarConfiguration -Configuration @{
            Alignment = 'Center'
            Search = 'Hidden'
            TaskView = 'Enabled'
            Widgets = 'Disabled'
            Copilot = 'Disabled'
            AutoHide = 'Disabled'
            ShowSeconds = 'Enabled'
        }

        $Result.IsValid | Should -BeTrue
        @($Result.Errors).Count | Should -Be 0
    }

    It 'accepts all supported alignment values' -ForEach @('Left', 'Center') {
        (Test-HermesTaskbarConfiguration -Configuration @{ Alignment = $_ }).IsValid |
            Should -BeTrue
    }

    It 'accepts all supported search values' -ForEach @(
        'Hidden'
        'Icon'
        'Box'
        'IconAndLabel'
    ) {
        (Test-HermesTaskbarConfiguration -Configuration @{ Search = $_ }).IsValid |
            Should -BeTrue
    }

    It 'canonicalizes supported Boolean aliases' {
        $Result = Test-HermesTaskbarConfiguration -Configuration @{
            ShowTaskView = $true
            ShowWidgets = $false
            ShowCopilot = $false
        }

        $Result.IsValid | Should -BeTrue
        $Result.Configuration.TaskView | Should -BeTrue
        $Result.Configuration.Widgets | Should -BeFalse
        $Result.Configuration.Copilot | Should -BeFalse
    }

    It 'accepts Boolean values for binary settings' -ForEach @(
        'TaskView'
        'Widgets'
        'Copilot'
        'AutoHide'
        'ShowSeconds'
    ) {
        (Test-HermesTaskbarConfiguration -Configuration @{ $_ = $true }).IsValid |
            Should -BeTrue
    }

    It 'rejects an empty configuration' {
        (Test-HermesTaskbarConfiguration -Configuration @{}).IsValid |
            Should -BeFalse
    }

    It 'rejects unsupported properties' {
        $Result = Test-HermesTaskbarConfiguration -Configuration @{
            InvalidSetting = $true
        }

        $Result.IsValid | Should -BeFalse
        $Result.Errors | Should -Contain "Unsupported taskbar setting 'InvalidSetting'."
    }

    It 'rejects duplicate canonical aliases' {
        $Result = Test-HermesTaskbarConfiguration -Configuration @{
            TaskView = 'Enabled'
            ShowTaskView = $true
        }

        $Result.IsValid | Should -BeFalse
        $Result.Errors -join ' ' | Should -Match 'duplicate aliases'
    }

    It 'rejects invalid alignment' {
        (Test-HermesTaskbarConfiguration -Configuration @{ Alignment = 'Right' }).IsValid |
            Should -BeFalse
    }

    It 'rejects invalid search mode' {
        (Test-HermesTaskbarConfiguration -Configuration @{ Search = 'Large' }).IsValid |
            Should -BeFalse
    }

    It 'rejects invalid binary setting values' -ForEach @(
        'TaskView'
        'Widgets'
        'Copilot'
        'AutoHide'
        'ShowSeconds'
    ) {
        (Test-HermesTaskbarConfiguration -Configuration @{ $_ = 'Sometimes' }).IsValid |
            Should -BeFalse
    }
}

Describe 'Get-HermesTaskbarSettings' {
    It 'maps supported Registry values to the canonical model' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarRegistryValue {
                param($Path, $Name)

                $Values = @{
                    TaskbarAl = 0
                    SearchboxTaskbarMode = 3
                    ShowTaskViewButton = 1
                    TaskbarDa = 0
                    TurnOffWindowsCopilot = 1
                    ShowSecondsInSystemClock = 1
                    Settings = [byte[]](0, 0, 0, 0, 0, 0, 0, 0, 3)
                }

                [pscustomobject]@{
                    Exists = $true
                    Value = $Values[$Name]
                }
            }

            $Result = Get-HermesTaskbarSettings

            $Result.Alignment | Should -Be 'Left'
            $Result.Search | Should -Be 'IconAndLabel'
            $Result.TaskView | Should -Be 'Enabled'
            $Result.Widgets | Should -Be 'Disabled'
            $Result.Copilot | Should -Be 'Disabled'
            $Result.AutoHide | Should -Be 'Enabled'
            $Result.ShowSeconds | Should -Be 'Enabled'
        }
    }

    It 'reports missing values as NotConfigured' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarRegistryValue {
                [pscustomobject]@{ Exists = $false; Value = $null }
            }

            $Result = Get-HermesTaskbarSettings

            $Result.Alignment | Should -Be 'NotConfigured'
            $Result.Search | Should -Be 'NotConfigured'
            $Result.TaskView | Should -Be 'NotConfigured'
            $Result.Widgets | Should -Be 'NotConfigured'
            $Result.Copilot | Should -Be 'NotConfigured'
            $Result.AutoHide | Should -Be 'NotConfigured'
            $Result.ShowSeconds | Should -Be 'NotConfigured'
        }
    }

    It 'reports unsupported alignment and search values as Unknown' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarRegistryValue {
                param($Path, $Name)

                switch ($Name) {
                    'TaskbarAl' { [pscustomobject]@{ Exists = $true; Value = 99 } }
                    'SearchboxTaskbarMode' { [pscustomobject]@{ Exists = $true; Value = 99 } }
                    default { [pscustomobject]@{ Exists = $false; Value = $null } }
                }
            }

            $Result = Get-HermesTaskbarSettings
            $Result.Alignment | Should -Be 'Unknown'
            $Result.Search | Should -Be 'Unknown'
        }
    }

    It 'does not silently classify unsupported AutoHide data as Disabled' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarRegistryValue {
                param($Path, $Name)

                if ($Name -eq 'Settings') {
                    return [pscustomobject]@{
                        Exists = $true
                        Value = [byte[]](0, 0, 0, 0, 0, 0, 0, 0, 99)
                    }
                }

                [pscustomobject]@{ Exists = $false; Value = $null }
            }

            (Get-HermesTaskbarSettings).AutoHide | Should -Be 'Unknown'
        }
    }
}

Describe 'Test-HermesTaskbarSettings' {
    It 'reports compliance when desired values match' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{
                    Alignment = 'Center'
                    Search = 'Hidden'
                    TaskView = 'Enabled'
                    Widgets = 'Disabled'
                    Copilot = 'Disabled'
                    AutoHide = 'Disabled'
                    ShowSeconds = 'Enabled'
                }
            }

            $Result = Test-HermesTaskbarSettings -Configuration @{
                Alignment = 'Center'
                Widgets = $false
            }

            $Result.IsCompliant | Should -BeTrue
            @($Result.Differences).Count | Should -Be 0
        }
    }

    It 'returns precise differences for noncompliant values' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{
                    Alignment = 'Left'
                    Search = 'Hidden'
                    TaskView = 'Enabled'
                    Widgets = 'Enabled'
                    Copilot = 'Disabled'
                    AutoHide = 'Disabled'
                    ShowSeconds = 'Disabled'
                }
            }

            $Result = Test-HermesTaskbarSettings -Configuration @{
                Alignment = 'Center'
                Widgets = $false
            }

            $Result.IsCompliant | Should -BeFalse
            @($Result.Differences).Count | Should -Be 2

            $AlignmentDifference = $Result.Differences |
                Where-Object Setting -eq 'Alignment'
            $WidgetsDifference = $Result.Differences |
                Where-Object Setting -eq 'Widgets'

            $AlignmentDifference.Expected | Should -Be 'Center'
            $AlignmentDifference.Actual | Should -Be 'Left'
            $WidgetsDifference.Expected | Should -Be 'Disabled'
            $WidgetsDifference.Actual | Should -Be 'Enabled'
        }
    }

    It 'throws for an invalid desired configuration' {
        {
            Test-HermesTaskbarSettings -Configuration @{ Alignment = 'Right' }
        } | Should -Throw
    }
}

Describe 'Backup-HermesTaskbarSettings' {
    It 'writes a standardized Taskbar backup' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{ Alignment = 'Center' }
            }
            Mock Get-HermesTaskbarRegistryValue {
                [pscustomobject]@{
                    Exists = $true
                    Value = [byte[]](0, 0, 0, 0, 0, 0, 0, 0, 2)
                }
            }
            Mock Write-HermesBackup {
                [pscustomobject]@{
                    ModuleName = $ModuleName
                    BackupPath = 'taskbar.json'
                    Settings = $Settings
                }
            }

            $Result = Backup-HermesTaskbarSettings

            $Result.ModuleName | Should -Be 'Taskbar'
            $Result.Settings.Alignment | Should -Be 'Center'
            Should -Invoke Write-HermesBackup -Times 1 -Exactly -ParameterFilter {
                $ModuleName -eq 'Taskbar' -and
                $AdditionalMetadata.TaskbarBackupFormat -eq '2.0' -and
                $AdditionalMetadata.AutoHideRegistry.Exists
            }
        }
    }

    It 'passes a custom backup directory to Core' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Center' } }
            Mock Get-HermesTaskbarRegistryValue {
                [pscustomobject]@{ Exists = $false; Value = $null }
            }
            Mock Write-HermesBackup { [pscustomobject]@{ BackupPath = 'custom.json' } }

            Backup-HermesTaskbarSettings -BackupDirectory 'C:\HermesBackups' |
                Out-Null

            Should -Invoke Write-HermesBackup -Times 1 -Exactly -ParameterFilter {
                $BackupDirectory -eq 'C:\HermesBackups'
            }
        }
    }
}

Describe 'Set-HermesTaskbarSettings' {
    It 'returns an unchanged result and does not back up compliant settings' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Center' } }
            Mock Test-HermesTaskbarSettings {
                [pscustomobject]@{
                    IsCompliant = $true
                    Differences = @()
                }
            }
            Mock Backup-HermesTaskbarSettings {}
            Mock Set-HermesRegistryDword {}

            $Result = Set-HermesTaskbarSettings -Configuration @{ Alignment = 'Center' }

            $Result.Changed | Should -BeFalse
            Should -Invoke Backup-HermesTaskbarSettings -Times 0
            Should -Invoke Set-HermesRegistryDword -Times 0
        }
    }

    It 'supports WhatIf without backup or Registry writes' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Left' } }
            Mock Test-HermesTaskbarSettings {
                [pscustomobject]@{ IsCompliant = $false; Differences = @('difference') }
            }
            Mock Backup-HermesTaskbarSettings {}
            Mock Set-HermesRegistryDword {}

            {
                Set-HermesTaskbarSettings `
                    -Configuration @{ Alignment = 'Center' } `
                    -WhatIf
            } | Should -Not -Throw

            Should -Invoke Backup-HermesTaskbarSettings -Times 0
            Should -Invoke Set-HermesRegistryDword -Times 0
        }
    }

    It 'maps canonical values to the expected Registry writes' {
        InModuleScope Hermes.Taskbar {
            $script:ComplianceCall = 0

            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{
                    Alignment = 'Left'
                    Search = 'Hidden'
                    TaskView = 'Disabled'
                    Widgets = 'Enabled'
                    Copilot = 'Enabled'
                    AutoHide = 'Disabled'
                    ShowSeconds = 'Disabled'
                }
            }
            Mock Test-HermesTaskbarSettings {
                $script:ComplianceCall++
                [pscustomobject]@{
                    IsCompliant = $script:ComplianceCall -gt 1
                    Differences = @()
                }
            }
            Mock Backup-HermesTaskbarSettings { [pscustomobject]@{ BackupPath = 'backup.json' } }
            Mock Set-HermesRegistryDword {}
            Mock Set-HermesTaskbarAutoHideState {}
            Mock Restart-HermesExplorer {
                [pscustomobject]@{
                    Requested = $true
                    Restarted = $true
                    ProcessId = 1234
                }
            }

            $Result = Set-HermesTaskbarSettings `
                -Configuration @{
                    Alignment = 'Center'
                    Search = 'IconAndLabel'
                    TaskView = 'Enabled'
                    Widgets = 'Disabled'
                    Copilot = 'Disabled'
                    AutoHide = 'Enabled'
                    ShowSeconds = 'Enabled'
                } `
                -RestartExplorer `
                -Confirm:$false

            @($Result).Count | Should -Be 1
            $Result.Changed | Should -BeTrue
            $Result.ExplorerRestarted | Should -BeTrue
            Should -Invoke Backup-HermesTaskbarSettings -Times 1
            Should -Invoke Set-HermesRegistryDword -Times 6
            Should -Invoke Set-HermesRegistryDword -Times 1 -ParameterFilter {
                $Name -eq 'TaskbarAl' -and $Value -eq 1
            }
            Should -Invoke Set-HermesRegistryDword -Times 1 -ParameterFilter {
                $Name -eq 'SearchboxTaskbarMode' -and $Value -eq 3
            }
            Should -Invoke Set-HermesRegistryDword -Times 1 -ParameterFilter {
                $Name -eq 'TurnOffWindowsCopilot' -and $Value -eq 1
            }
            Should -Invoke Set-HermesTaskbarAutoHideState -Times 1
            Should -Invoke Restart-HermesExplorer -Times 1
        }
    }

    It 'does not create a backup when SkipBackup is used' {
        InModuleScope Hermes.Taskbar {
            $script:ComplianceCall = 0
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Left' } }
            Mock Test-HermesTaskbarSettings {
                $script:ComplianceCall++
                [pscustomobject]@{
                    IsCompliant = $script:ComplianceCall -gt 1
                    Differences = @()
                }
            }
            Mock Backup-HermesTaskbarSettings {}
            Mock Set-HermesRegistryDword {}

            Set-HermesTaskbarSettings `
                -Configuration @{ Alignment = 'Center' } `
                -SkipBackup `
                -Confirm:$false |
                Out-Null

            Should -Invoke Backup-HermesTaskbarSettings -Times 0
        }
    }

    It 'throws contextual information when a Registry write fails' {
        InModuleScope Hermes.Taskbar {
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Left' } }
            Mock Test-HermesTaskbarSettings {
                [pscustomobject]@{ IsCompliant = $false; Differences = @() }
            }
            Mock Backup-HermesTaskbarSettings { [pscustomobject]@{ BackupPath = 'backup.json' } }
            Mock Set-HermesRegistryDword { throw 'Registry denied' }

            {
                Set-HermesTaskbarSettings `
                    -Configuration @{ Alignment = 'Center' } `
                    -Confirm:$false
            } | Should -Throw '*Unable to apply Hermes taskbar settings*Registry denied*backup.json*'
        }
    }

    It 'throws when post-change verification fails' {
        InModuleScope Hermes.Taskbar {
            $script:ComplianceCall = 0
            Mock Get-HermesTaskbarSettings { [pscustomobject]@{ Alignment = 'Left' } }
            Mock Test-HermesTaskbarSettings {
                $script:ComplianceCall++
                [pscustomobject]@{
                    IsCompliant = $false
                    Differences = @(
                        [pscustomobject]@{
                            Setting = 'Alignment'
                            Expected = 'Center'
                            Actual = 'Left'
                        }
                    )
                }
            }
            Mock Backup-HermesTaskbarSettings { [pscustomobject]@{ BackupPath = 'backup.json' } }
            Mock Set-HermesRegistryDword {}

            {
                Set-HermesTaskbarSettings `
                    -Configuration @{ Alignment = 'Center' } `
                    -Confirm:$false
            } | Should -Throw '*Taskbar verification failed*Alignment*'
        }
    }
}

Describe 'Restore-HermesTaskbarSettings' {
    It 'throws when the backup file is missing' {
        {
            Restore-HermesTaskbarSettings `
                -BackupPath (Join-Path $TestDrive 'missing.json') `
                -Confirm:$false
        } | Should -Throw
    }

    It 'rejects backups that contain no restorable settings' {
        InModuleScope Hermes.Taskbar {
            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{
                        Alignment = 'Unknown'
                        Search = 'Unknown'
                    }
                }
            }

            {
                Restore-HermesTaskbarSettings `
                    -BackupPath 'empty.json' `
                    -Confirm:$false
            } | Should -Throw '*no restorable taskbar settings*'
        }
    }

    It 'returns unchanged when the backup already matches' {
        InModuleScope Hermes.Taskbar {
            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{ Alignment = 'Center' }
                }
            }
            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{ Alignment = 'Center' }
            }
            Mock Backup-HermesTaskbarSettings {}
            Mock Set-HermesTaskbarSettings {}

            $Result = Restore-HermesTaskbarSettings `
                -BackupPath 'matching.json' `
                -Confirm:$false

            $Result.Changed | Should -BeFalse
            Should -Invoke Backup-HermesTaskbarSettings -Times 0
            Should -Invoke Set-HermesTaskbarSettings -Times 0
        }
    }

    It 'supports WhatIf without safety backup or restore writes' {
        InModuleScope Hermes.Taskbar {
            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{ Alignment = 'Center' }
                }
            }
            Mock Get-HermesTaskbarSettings {
                [pscustomobject]@{ Alignment = 'Left' }
            }
            Mock Backup-HermesTaskbarSettings {}
            Mock Set-HermesTaskbarSettings {}

            Restore-HermesTaskbarSettings `
                -BackupPath 'restore.json' `
                -CreateSafetyBackup `
                -WhatIf |
                Should -BeNullOrEmpty

            Should -Invoke Backup-HermesTaskbarSettings -Times 0
            Should -Invoke Set-HermesTaskbarSettings -Times 0
        }
    }

    It 'creates a safety backup and applies restorable settings' {
        InModuleScope Hermes.Taskbar {
            $script:RestoreSettingsCall = 0

            Mock Read-HermesBackup {
                [pscustomobject]@{
                    Settings = [pscustomobject]@{
                        Alignment = 'Center'
                        Search = 'NotConfigured'
                        TaskView = 'Enabled'
                    }
                }
            }
            Mock Get-HermesTaskbarSettings {
                $script:RestoreSettingsCall++

                if ($script:RestoreSettingsCall -eq 1) {
                    return [pscustomobject]@{
                        Alignment = 'Left'
                        Search = 'Hidden'
                        TaskView = 'Disabled'
                    }
                }

                [pscustomobject]@{
                    Alignment = 'Center'
                    Search = 'NotConfigured'
                    TaskView = 'Enabled'
                }
            }
            Mock Backup-HermesTaskbarSettings {
                [pscustomobject]@{ BackupPath = 'safety.json' }
            }
            Mock Set-HermesTaskbarSettings {
                [pscustomobject]@{
                    Changed = $true
                    Verification = [pscustomobject]@{ IsCompliant = $true }
                    ExplorerRestarted = $false
                }
            }
            Mock Remove-HermesRegistryValue {
                [pscustomobject]@{ Existed = $true; Removed = $true }
            }

            $Result = Restore-HermesTaskbarSettings `
                -BackupPath 'restore.json' `
                -CreateSafetyBackup `
                -Confirm:$false

            $Result.Changed | Should -BeTrue
            $Result.SafetyBackup.BackupPath | Should -Be 'safety.json'
            Should -Invoke Backup-HermesTaskbarSettings -Times 1
            Should -Invoke Remove-HermesRegistryValue -Times 1 -ParameterFilter {
                $Name -eq 'SearchboxTaskbarMode'
            }
            Should -Invoke Set-HermesTaskbarSettings -Times 1 -ParameterFilter {
                $Configuration.Alignment -eq 'Center' -and
                $Configuration.TaskView -eq 'Enabled' -and
                -not $Configuration.Contains('Search')
            }
        }
    }
}
