BeforeAll {
    $script:ModuleRoot=Split-Path $PSScriptRoot -Parent
    $script:ManifestPath=Join-Path $script:ModuleRoot 'Hermes.PowerToys.psd1'
    $script:RepositoryRoot=Split-Path (Split-Path (Split-Path $script:ModuleRoot -Parent) -Parent) -Parent
    $script:ConfigurationPath=Join-Path $script:RepositoryRoot 'configs\powertoys\hermes-powertoys-base.psd1'
    Remove-Module Hermes.PowerToys -Force -ErrorAction SilentlyContinue
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
    $script:Configuration=Import-PowerShellDataFile $script:ConfigurationPath
}
AfterAll { Remove-Module Hermes.PowerToys -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.PowerToys module contract' {
    It 'has a valid manifest' {
        { Test-ModuleManifest $script:ManifestPath -ErrorAction Stop }|Should -Not -Throw
    }
    It 'uses version 0.5.0' {
        (Test-ModuleManifest $script:ManifestPath).Version.ToString()|Should -Be '0.5.0'
    }
    It 'exports exactly six commands' {
        @(Get-Command -Module Hermes.PowerToys).Count|Should -Be 6
    }
    It 'provides help for every command' {
        foreach($command in Get-Command -Module Hermes.PowerToys){
            (Get-Help $command.Name).Synopsis|Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes PowerToys configuration' {
    It 'exists and validates' {
        Test-Path $script:ConfigurationPath|Should -BeTrue
        (Test-HermesPowerToysConfiguration $script:Configuration).IsValid|Should -BeTrue
    }
    It 'rejects an empty configuration' {
        (Test-HermesPowerToysConfiguration @{}).IsValid|Should -BeFalse
    }
    It 'rejects unsupported settings' {
        (Test-HermesPowerToysConfiguration @{Features=@{Unsupported=$true}}).IsValid|Should -BeFalse
    }
    It 'rejects non-Boolean feature values' {
        (Test-HermesPowerToysConfiguration @{Features=@{FancyZones='yes'}}).IsValid|Should -BeFalse
    }
}

Describe 'PowerToys settings lifecycle' {
    BeforeEach {
        $script:SettingsPath=Join-Path $TestDrive 'PowerToys\settings.json'
        New-Item -ItemType Directory -Path (Split-Path $script:SettingsPath) -Force|Out-Null
        @{
            powertoys_version='0.100.2'
            startup=$false
            theme='system'
            enabled=@{FancyZones=$false;Awake=$true;Unmanaged=$true}
            preserved='value'
        }|ConvertTo-Json -Depth 10|Set-Content $script:SettingsPath -Encoding utf8NoBOM
    }
    It 'reports initial noncompliance' {
        (Test-HermesPowerToysSettings $script:Configuration $script:SettingsPath).IsCompliant|Should -BeFalse
    }
    It 'supports WhatIf without changing the file' {
        $before=[Convert]::ToBase64String([IO.File]::ReadAllBytes($script:SettingsPath))
        Set-HermesPowerToysSettings $script:Configuration $script:SettingsPath -SkipBackup -WhatIf
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($script:SettingsPath))|Should -Be $before
    }
    It 'applies and verifies the baseline' {
        Set-HermesPowerToysSettings $script:Configuration $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null
        (Test-HermesPowerToysSettings $script:Configuration $script:SettingsPath).IsCompliant|Should -BeTrue
    }
    It 'preserves unmanaged settings and features' {
        Set-HermesPowerToysSettings $script:Configuration $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null
        $document=Get-Content $script:SettingsPath -Raw|ConvertFrom-Json -AsHashtable
        $document.preserved|Should -Be 'value'
        $document.enabled.Unmanaged|Should -BeTrue
    }
    It 'is idempotent' {
        Set-HermesPowerToysSettings $script:Configuration $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null
        (Set-HermesPowerToysSettings $script:Configuration $script:SettingsPath -SkipBackup -Confirm:$false).Changed|Should -BeFalse
    }
    It 'backs up and restores exact bytes' {
        $backup=Backup-HermesPowerToysSettings $script:SettingsPath (Join-Path $TestDrive 'Backups')
        $expected=[Convert]::ToBase64String([IO.File]::ReadAllBytes($script:SettingsPath))
        Set-Content $script:SettingsPath '{"changed":true}' -Encoding utf8NoBOM
        Restore-HermesPowerToysSettings $backup.BackupPath -Confirm:$false|Out-Null
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($script:SettingsPath))|Should -Be $expected
    }
}
