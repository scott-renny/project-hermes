$discoveryManifest = Join-Path $PSScriptRoot '..\Hermes.Terminal.psd1'
Import-Module $discoveryManifest -Force -ErrorAction Stop

BeforeAll {
    $script:Manifest=Join-Path $PSScriptRoot '..\Hermes.Terminal.psd1'
    $script:ConfigPath=Join-Path $PSScriptRoot '..\..\..\..\configs\terminal\hermes-terminal-base.psd1'
    Remove-Module Hermes.Terminal -Force -ErrorAction SilentlyContinue
    Import-Module $script:Manifest -Force -ErrorAction Stop
    $script:Config=Import-PowerShellDataFile $script:ConfigPath
}
AfterAll { Remove-Module Hermes.Terminal -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.Terminal module contract' {
    It 'has a valid manifest' { {Test-ModuleManifest $script:Manifest -ErrorAction Stop}|Should -Not -Throw }
    It 'uses version 0.5.0' { (Test-ModuleManifest $script:Manifest).Version.ToString()|Should -Be '0.5.0' }
    It 'exports exactly six commands' { @(Get-Command -Module Hermes.Terminal).Count|Should -Be 6 }
    It 'provides help for every command' { foreach($c in Get-Command -Module Hermes.Terminal){(Get-Help $c.Name).Synopsis|Should -Not -BeNullOrEmpty} }
}

Describe 'Hermes Terminal configuration' {
    It 'exists and validates' { Test-Path $script:ConfigPath|Should -BeTrue; (Test-HermesTerminalConfiguration $script:Config).IsValid|Should -BeTrue }
    It 'rejects an empty configuration' { (Test-HermesTerminalConfiguration @{}).IsValid|Should -BeFalse }
    It 'rejects unsupported settings' { (Test-HermesTerminalConfiguration @{Unknown=$true}).IsValid|Should -BeFalse }
    It 'rejects invalid colors' { $bad=$script:Config.Clone();$bad.Scheme=$script:Config.Scheme.Clone();$bad.Scheme.Cyan='cyan';(Test-HermesTerminalConfiguration $bad).IsValid|Should -BeFalse }
}

Describe 'Windows Terminal settings lifecycle' {
    BeforeEach {
        $script:SettingsPath=Join-Path $TestDrive 'LocalState\settings.json'
        New-Item -ItemType Directory -Path (Split-Path $script:SettingsPath) -Force|Out-Null
        $seed=@{defaultProfile='{test-guid}';profiles=@{defaults=@{};list=@(@{guid='{test-guid}';name='PowerShell'})};schemes=@(@{name='Unrelated';foreground='#FFFFFF';background='#000000'})}
        $seed|ConvertTo-Json -Depth 20|Set-Content $script:SettingsPath -Encoding utf8NoBOM
    }
    It 'reports a noncompliant initial state' { (Test-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath).IsCompliant|Should -BeFalse }
    It 'supports WhatIf without changing the file' { $before=Get-Content $script:SettingsPath -Raw;Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -WhatIf;Get-Content $script:SettingsPath -Raw|Should -BeExactly $before }
    It 'applies and verifies the profile' { $r=Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false;$r.Changed|Should -BeTrue;(Test-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath).IsCompliant|Should -BeTrue }
    It 'preserves unrelated profiles and schemes' { Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null;$d=Get-Content $script:SettingsPath -Raw|ConvertFrom-Json -AsHashtable;$d.defaultProfile|Should -Be '{test-guid}';@($d.schemes.name)|Should -Contain 'Unrelated' }
    It 'is idempotent' { Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null;(Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false).Changed|Should -BeFalse }
    It 'replaces the Hermes scheme without duplication' { Set-HermesTerminalSettings $script:Config -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null;$changed=$script:Config.Clone();$changed.Scheme=$script:Config.Scheme.Clone();$changed.Scheme.Cyan='#00FFFF';Set-HermesTerminalSettings $changed -SettingsPath $script:SettingsPath -SkipBackup -Confirm:$false|Out-Null;$d=Get-Content $script:SettingsPath -Raw|ConvertFrom-Json -AsHashtable;@($d.schemes|Where-Object name -eq 'Project Hermes').Count|Should -Be 1 }
}
