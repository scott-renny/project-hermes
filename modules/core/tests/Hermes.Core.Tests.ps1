$moduleManifest = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath '..\Hermes.Core.psd1'

Import-Module `
    -Name $moduleManifest `
    -Force `
    -ErrorAction Stop

$exportTestCases = @(
    @{ FunctionName = 'Get-HermesRepositoryRoot' }
    @{ FunctionName = 'Get-HermesVersion' }
    @{ FunctionName = 'New-HermesGuid' }
    @{ FunctionName = 'Write-HermesBackup' }
    @{ FunctionName = 'Read-HermesBackup' }
)

AfterAll {
    Remove-Module `
        -Name Hermes.Core `
        -ErrorAction SilentlyContinue
}

Describe 'Hermes.Core module' {
    Context 'Module loading and exports' {
        It 'imports successfully' {
            Get-Module -Name Hermes.Core |
                Should -Not -BeNullOrEmpty
        }

        It 'exports <FunctionName>' -ForEach $exportTestCases {
            param(
                [string]$FunctionName
            )

            Get-Command `
                -Name $FunctionName `
                -Module Hermes.Core `
                -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }
    }
}

InModuleScope Hermes.Core {
    Describe 'Get-HermesRepositoryRoot' {
        It 'returns an existing directory' {
            $result = Get-HermesRepositoryRoot

            Test-Path `
                -LiteralPath $result `
                -PathType Container |
                Should -BeTrue
        }
    }

    Describe 'Get-HermesVersion' {
        It 'returns the executing module version' {
            Get-HermesVersion |
                Should -Be '0.1.1'
        }
    }

    Describe 'New-HermesGuid' {
        It 'returns a valid GUID string' {
            $result = New-HermesGuid
            $parsed = [guid]::Empty

            [guid]::TryParse($result, [ref]$parsed) |
                Should -BeTrue
        }
    }

    Describe 'Write-HermesBackup' {
        BeforeEach {
            $testDirectory = Join-Path `
                -Path $TestDrive `
                -ChildPath 'backups'
        }

        It 'creates a backup file' {
            $settings = [PSCustomObject]@{
                ExampleSetting = $true
            }

            $result = Write-HermesBackup `
                -ModuleName 'TestModule' `
                -Settings $settings `
                -BackupDirectory $testDirectory

            Test-Path `
                -LiteralPath $result.BackupPath `
                -PathType Leaf |
                Should -BeTrue
        }

        It 'writes standardized metadata' {
            $settings = [PSCustomObject]@{
                ExampleSetting = $true
            }

            $result = Write-HermesBackup `
                -ModuleName 'TestModule' `
                -Settings $settings `
                -BackupDirectory $testDirectory

            $document = Get-Content `
                -LiteralPath $result.BackupPath `
                -Raw |
                ConvertFrom-Json

            $document.SchemaVersion |
                Should -Be '1.0'

            $document.ModuleName |
                Should -Be 'TestModule'

            $document.HermesVersion |
                Should -Be '0.1.1'

            $document.Settings.ExampleSetting |
                Should -BeTrue
        }
    }

    Describe 'Read-HermesBackup' {
        BeforeEach {
            $testDirectory = Join-Path `
                -Path $TestDrive `
                -ChildPath 'read-backups'

            $settings = [PSCustomObject]@{
                ExampleSetting = 'Value'
            }

            $writtenBackup = Write-HermesBackup `
                -ModuleName 'TestModule' `
                -Settings $settings `
                -BackupDirectory $testDirectory
        }

        It 'reads a valid backup' {
            $document = Read-HermesBackup `
                -BackupPath $writtenBackup.BackupPath

            $document.ModuleName |
                Should -Be 'TestModule'

            $document.Settings.ExampleSetting |
                Should -Be 'Value'
        }

        It 'accepts the expected module name' {
            {
                Read-HermesBackup `
                    -BackupPath $writtenBackup.BackupPath `
                    -ExpectedModuleName 'TestModule'
            } |
                Should -Not -Throw
        }

        It 'rejects a backup from another module' {
            {
                Read-HermesBackup `
                    -BackupPath $writtenBackup.BackupPath `
                    -ExpectedModuleName 'AnotherModule'
            } |
                Should -Throw `
                    -ExpectedMessage `
                    "*not 'AnotherModule'*"
        }

        It 'rejects a missing backup file' {
            {
                Read-HermesBackup `
                    -BackupPath (Join-Path $TestDrive 'missing.json')
            } |
                Should -Throw `
                    -ExpectedMessage `
                    '*could not be found*'
        }
    }
}
