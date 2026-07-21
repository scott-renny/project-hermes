$discoveryManifest=Join-Path $PSScriptRoot '..\Hermes.Git.psd1'
Import-Module $discoveryManifest -Force -ErrorAction Stop

BeforeAll{
    $script:Manifest=Join-Path $PSScriptRoot '..\Hermes.Git.psd1'
    $script:ConfigPath=Join-Path $PSScriptRoot '..\..\..\..\configs\git\hermes-git-base.psd1'
    $script:OriginalGlobalConfig=$env:GIT_CONFIG_GLOBAL
    Remove-Module Hermes.Git -Force -ErrorAction SilentlyContinue
    Import-Module $script:Manifest -Force -ErrorAction Stop
    $script:Config=Import-PowerShellDataFile $script:ConfigPath
}
AfterAll{
    $env:GIT_CONFIG_GLOBAL=$script:OriginalGlobalConfig
    Remove-Module Hermes.Git -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Git module contract'{
    It 'has a valid manifest'{{Test-ModuleManifest $script:Manifest -ErrorAction Stop}|Should -Not -Throw}
    It 'uses version 0.5.0'{(Test-ModuleManifest $script:Manifest).Version.ToString()|Should -Be '0.5.0'}
    It 'exports exactly six commands'{@(Get-Command -Module Hermes.Git).Count|Should -Be 6}
    It 'provides help for every command'{foreach($c in Get-Command -Module Hermes.Git){(Get-Help $c.Name).Synopsis|Should -Not -BeNullOrEmpty}}
}

Describe 'Hermes Git configuration'{
    It 'exists and validates'{Test-Path $script:ConfigPath|Should -BeTrue;(Test-HermesGitConfiguration $script:Config).IsValid|Should -BeTrue}
    It 'rejects an empty configuration'{(Test-HermesGitConfiguration @{}).IsValid|Should -BeFalse}
    It 'rejects unsupported settings'{(Test-HermesGitConfiguration @{Unknown='value'}).IsValid|Should -BeFalse}
    It 'accepts partial desired state'{(Test-HermesGitConfiguration @{DefaultBranch='main'}).IsValid|Should -BeTrue}
    It 'normalizes Boolean values'{(Test-HermesGitConfiguration @{FetchPrune=$true}).Configuration.FetchPrune|Should -Be 'true'}
}

Describe 'Global Git settings lifecycle'{
    BeforeEach{
        $script:TestConfig=Join-Path $TestDrive 'global.gitconfig'
        $env:GIT_CONFIG_GLOBAL=$script:TestConfig
        Remove-Item $script:TestConfig -Force -ErrorAction SilentlyContinue
    }
    It 'reports missing settings as NotConfigured'{(Get-HermesGitSettings).DefaultBranch|Should -Be 'NotConfigured'}
    It 'reports initial noncompliance'{(Test-HermesGitSettings $script:Config).IsCompliant|Should -BeFalse}
    It 'supports WhatIf without creating configuration'{Set-HermesGitSettings $script:Config -WhatIf;Test-Path $script:TestConfig|Should -BeFalse}
    It 'applies and verifies the baseline'{$r=Set-HermesGitSettings $script:Config -SkipBackup -Confirm:$false;$r.Changed|Should -BeTrue;(Test-HermesGitSettings $script:Config).IsCompliant|Should -BeTrue}
    It 'is idempotent'{Set-HermesGitSettings $script:Config -SkipBackup -Confirm:$false|Out-Null;(Set-HermesGitSettings $script:Config -SkipBackup -Confirm:$false).Changed|Should -BeFalse}
    It 'preserves unmanaged identity settings'{git config --global user.name 'Hermes Test User';Set-HermesGitSettings $script:Config -SkipBackup -Confirm:$false|Out-Null;(git config --global --get user.name)|Should -Be 'Hermes Test User'}
    It 'supports a partial update'{Set-HermesGitSettings @{DefaultBranch='develop'} -SkipBackup -Confirm:$false|Out-Null;(Get-HermesGitSettings).DefaultBranch|Should -Be 'develop'}
}
