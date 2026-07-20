BeforeAll {
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $manifestPath = Join-Path $moduleRoot 'Hermes.Taskbar.psd1'

    Import-Module $manifestPath -Force
}

AfterAll {
    Remove-Module Hermes.Taskbar -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Taskbar module' {
    It 'has a valid module manifest' {
        $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Hermes.Taskbar.psd1'

        {
            Test-ModuleManifest $manifestPath -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'exports exactly the expected public commands' {
        $expected = @(
            'Backup-HermesTaskbarSettings'
            'Get-HermesTaskbarSettings'
            'Restore-HermesTaskbarSettings'
            'Set-HermesTaskbarSettings'
            'Test-HermesTaskbarConfiguration'
            'Test-HermesTaskbarSettings'
        ) | Sort-Object

        $actual = Get-Command -Module Hermes.Taskbar |
            Select-Object -ExpandProperty Name |
            Sort-Object

        Compare-Object -ReferenceObject $expected -DifferenceObject $actual |
            Should -BeNullOrEmpty
    }
}

Describe 'Test-HermesTaskbarConfiguration' {
    It 'accepts the canonical configuration model' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            Alignment   = 'Center'
            Search      = 'Hidden'
            TaskView    = 'Enabled'
            Widgets     = 'Disabled'
            Copilot     = 'Disabled'
            AutoHide    = 'Disabled'
            ShowSeconds = 'Enabled'
        }

        $result.IsValid | Should -BeTrue
        @($result.Errors).Count | Should -Be 0
    }

    It 'accepts supported Boolean aliases' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            ShowTaskView = $true
            ShowWidgets  = $false
            ShowCopilot  = $false
        }

        $result.IsValid | Should -BeTrue
        $result.Configuration.TaskView | Should -BeTrue
        $result.Configuration.Widgets | Should -BeFalse
        $result.Configuration.Copilot | Should -BeFalse
    }

    It 'rejects unsupported properties' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            InvalidSetting = $true
        }

        $result.IsValid | Should -BeFalse
        $result.Errors |
            Should -Contain "Unsupported taskbar setting 'InvalidSetting'."
    }

    It 'rejects an invalid alignment' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            Alignment = 'Right'
        }

        $result.IsValid | Should -BeFalse
    }

    It 'rejects an invalid search mode' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            Search = 'Large'
        }

        $result.IsValid | Should -BeFalse
    }

    It 'rejects invalid enabled-state values' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            TaskView = 'Sometimes'
        }

        $result.IsValid | Should -BeFalse
    }

    It 'rejects an empty configuration' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{}

        $result.IsValid | Should -BeFalse
    }

    It 'rejects duplicate canonical aliases' {
        $result = Test-HermesTaskbarConfiguration -Configuration @{
            TaskView     = 'Enabled'
            ShowTaskView = $true
        }

        $result.IsValid | Should -BeFalse
    }
}

Describe 'Set-HermesTaskbarSettings safety behavior' {
    It 'supports WhatIf' {
        {
            Set-HermesTaskbarSettings `
                -Configuration @{ Alignment = 'Center' } `
                -WhatIf
        } | Should -Not -Throw
    }
}

Describe 'Restore-HermesTaskbarSettings safety behavior' {
    It 'throws when the backup file is missing' {
        {
            Restore-HermesTaskbarSettings `
                -BackupPath (Join-Path $TestDrive 'missing.json') `
                -Confirm:$false
        } | Should -Throw
    }
}
