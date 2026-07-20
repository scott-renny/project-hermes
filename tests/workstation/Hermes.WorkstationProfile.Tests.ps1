BeforeAll {
    $script:RepositoryRoot = Split-Path `
        -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -Parent

    $script:ProfilePath = Join-Path `
        $script:RepositoryRoot `
        'configs\profiles\hermes-workstation-base.psd1'

    $script:ExpectedComponents = @(
        'Winget'
        'Windows'
        'Explorer'
        'Taskbar'
        'Desktop'
        'Terminal'
        'Git'
        'VSCode'
        'PowerToys'
        'PowerShell'
    )

    $script:ValidationCommands = @{
        Winget     = 'Test-HermesWingetConfiguration'
        Windows    = 'Test-HermesWindowsConfiguration'
        Explorer   = 'Test-HermesExplorerConfiguration'
        Taskbar    = 'Test-HermesTaskbarConfiguration'
        Desktop    = 'Test-HermesDesktopConfiguration'
        Terminal   = 'Test-HermesTerminalConfiguration'
        Git        = 'Test-HermesGitConfiguration'
        VSCode     = 'Test-HermesVSCodeConfiguration'
        PowerToys  = 'Test-HermesPowerToysConfiguration'
        PowerShell = 'Test-HermesPowerShellConfiguration'
    }

    $script:Profile = Import-PowerShellDataFile `
        -LiteralPath $script:ProfilePath
}

AfterAll {
    foreach ($componentName in $script:ExpectedComponents) {
        Remove-Module `
            -Name "Hermes.$componentName" `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

Describe 'Hermes unified workstation profile contract' {
    It 'exists as a PowerShell data file' {
        Test-Path `
            -LiteralPath $script:ProfilePath `
            -PathType Leaf |
            Should -BeTrue
    }

    It 'uses schema version 1.0' {
        $script:Profile.SchemaVersion |
            Should -Be '1.0'
    }

    It 'targets the supported Windows and PowerShell platform' {
        $script:Profile.Platform.OperatingSystem |
            Should -Be 'Windows 11'

        $script:Profile.Platform.SupportedEditions |
            Should -Contain 'Home'

        [version]$script:Profile.Platform.MinimumPowerShellVersion |
            Should -BeGreaterOrEqual ([version]'7.0')
    }

    It 'contains exactly the expected components' {
        @($script:Profile.Components.Keys).Count |
            Should -Be $script:ExpectedComponents.Count

        foreach ($componentName in $script:ExpectedComponents) {
            $script:Profile.Components.Keys |
                Should -Contain $componentName
        }
    }

    It 'defines every component exactly once in execution order' {
        @($script:Profile.Order).Count |
            Should -Be $script:ExpectedComponents.Count

        @($script:Profile.Order | Select-Object -Unique).Count |
            Should -Be $script:ExpectedComponents.Count

        foreach ($componentName in $script:ExpectedComponents) {
            $script:Profile.Order |
                Should -Contain $componentName
        }
    }

    It 'uses relative existing module and configuration paths' {
        foreach ($componentName in $script:ExpectedComponents) {
            $component = $script:Profile.Components[$componentName]

            [IO.Path]::IsPathRooted($component.ModulePath) |
                Should -BeFalse

            [IO.Path]::IsPathRooted($component.ConfigurationPath) |
                Should -BeFalse

            Test-Path `
                -LiteralPath (Join-Path $script:RepositoryRoot $component.ModulePath) `
                -PathType Leaf |
                Should -BeTrue

            Test-Path `
                -LiteralPath (Join-Path $script:RepositoryRoot $component.ConfigurationPath) `
                -PathType Leaf |
                Should -BeTrue
        }
    }

    It 'uses valid module manifests for every component' {
        foreach ($componentName in $script:ExpectedComponents) {
            $manifestPath = Join-Path `
                $script:RepositoryRoot `
                $script:Profile.Components[$componentName].ModulePath

            {
                Test-ModuleManifest `
                    -Path $manifestPath `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }
    }

    It 'contains a valid configuration for every component' {
        foreach ($componentName in $script:ExpectedComponents) {
            $component = $script:Profile.Components[$componentName]
            $manifestPath = Join-Path `
                $script:RepositoryRoot `
                $component.ModulePath
            $configurationPath = Join-Path `
                $script:RepositoryRoot `
                $component.ConfigurationPath

            Import-Module `
                -Name $manifestPath `
                -Force `
                -ErrorAction Stop

            $configuration = Import-PowerShellDataFile `
                -LiteralPath $configurationPath
            $validationCommand = $script:ValidationCommands[$componentName]
            $validation = & $validationCommand `
                -Configuration $configuration

            $validation.IsValid |
                Should -BeTrue
        }
    }

    It 'marks optional application components as non-required' {
        foreach ($componentName in @('Terminal', 'VSCode', 'PowerToys')) {
            $script:Profile.Components[$componentName].Required |
                Should -BeFalse
        }
    }
}
