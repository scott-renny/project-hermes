BeforeAll {
    $script:ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $script:ManifestPath = Join-Path -Path $script:ModuleRoot -ChildPath 'Hermes.VSCode.psd1'
    $script:RepositoryRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $script:ModuleRoot -Parent) -Parent) -Parent
    $script:ConfigurationPath = Join-Path -Path $script:RepositoryRoot -ChildPath 'configs\vscode\hermes-vscode-base.psd1'

    Remove-Module -Name 'Hermes.VSCode' -Force -ErrorAction SilentlyContinue
    Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop

    $script:Configuration = Import-PowerShellDataFile -LiteralPath $script:ConfigurationPath
}

AfterAll {
    Remove-Module -Name 'Hermes.VSCode' -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.VSCode module contract' {
    It 'has a valid manifest' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } |
            Should -Not -Throw
    }

    It 'uses version 0.5.0' {
        (Test-ModuleManifest -Path $script:ManifestPath).Version.ToString() |
            Should -Be '0.5.0'
    }

    It 'exports exactly six commands' {
        $expected = @(
            'Backup-HermesVSCodeSettings'
            'Get-HermesVSCodeSettings'
            'Restore-HermesVSCodeSettings'
            'Set-HermesVSCodeSettings'
            'Test-HermesVSCodeConfiguration'
            'Test-HermesVSCodeSettings'
        )

        @(Get-Command -Module 'Hermes.VSCode').Name |
            Sort-Object |
            Should -Be ($expected | Sort-Object)
    }

    It 'provides help for every public command' {
        foreach ($command in Get-Command -Module 'Hermes.VSCode') {
            (Get-Help -Name $command.Name).Synopsis |
                Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes VS Code configuration' {
    It 'exists and validates' {
        Test-Path -LiteralPath $script:ConfigurationPath -PathType Leaf |
            Should -BeTrue

        (Test-HermesVSCodeConfiguration -Configuration $script:Configuration).IsValid |
            Should -BeTrue
    }

    It 'rejects an empty configuration' {
        (Test-HermesVSCodeConfiguration -Configuration @{}).IsValid |
            Should -BeFalse
    }

    It 'rejects unsupported top-level settings' {
        $invalid = @{
            Settings    = $script:Configuration.Settings
            Extensions  = @('ms-vscode.powershell')
        }

        (Test-HermesVSCodeConfiguration -Configuration $invalid).IsValid |
            Should -BeFalse
    }

    It 'rejects unsupported editor settings' {
        $invalid = @{
            Settings = @{
                'hermes.unsupportedSetting' = $true
            }
        }

        (Test-HermesVSCodeConfiguration -Configuration $invalid).IsValid |
            Should -BeFalse
    }
}

Describe 'VS Code settings lifecycle' {
    BeforeEach {
        $script:SettingsPath = Join-Path -Path $TestDrive -ChildPath 'User\settings.json'
        $settingsDirectory = Split-Path -Path $script:SettingsPath -Parent
        New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
    }

    It 'reports a noncompliant absent settings file' {
        (Test-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath).IsCompliant |
            Should -BeFalse
    }

    It 'backs up an absent settings file with exact restore metadata' {
        $backupDirectory = Join-Path -Path $TestDrive -ChildPath 'Backups'
        $backup = Backup-HermesVSCodeSettings -SettingsPath $script:SettingsPath -BackupDirectory $backupDirectory

        $backup.ModuleName |
            Should -Be 'Hermes.VSCode'

        $backup.Settings.Existed |
            Should -BeFalse

        $backup.Settings.ContentBase64 |
            Should -Be ''
    }

    It 'supports WhatIf without creating a settings file' {
        Set-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath -SkipBackup -WhatIf

        Test-Path -LiteralPath $script:SettingsPath |
            Should -BeFalse
    }

    It 'applies and verifies managed settings' {
        Set-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false |
            Out-Null

        (Test-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath).IsCompliant |
            Should -BeTrue
    }

    It 'preserves unrelated settings and accepts JSONC input' {
        @'
{
    // Preserve this user preference.
    "files.trimTrailingWhitespace": true,
}
'@ | Set-Content -LiteralPath $script:SettingsPath -Encoding utf8NoBOM

        Set-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false |
            Out-Null

        $settings = Get-Content -LiteralPath $script:SettingsPath -Raw | ConvertFrom-Json -AsHashtable
        $settings['files.trimTrailingWhitespace'] |
            Should -BeTrue
    }

    It 'is idempotent' {
        Set-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false |
            Out-Null

        $result = Set-HermesVSCodeSettings -Configuration $script:Configuration -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false

        $result.Changed |
            Should -BeFalse
    }
}
