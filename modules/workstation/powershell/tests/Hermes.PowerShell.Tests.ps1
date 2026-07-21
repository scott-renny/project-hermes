$discoveryManifest = Join-Path $PSScriptRoot '..\Hermes.PowerShell.psd1'
Import-Module $discoveryManifest -Force -ErrorAction Stop

BeforeAll {
    $script:Manifest = Join-Path $PSScriptRoot '..\Hermes.PowerShell.psd1'
    $script:ProfileConfig = Join-Path $PSScriptRoot '..\..\..\..\configs\powershell\hermes-powershell-base.psd1'
    Remove-Module Hermes.PowerShell -Force -ErrorAction SilentlyContinue
    Import-Module $script:Manifest -Force -ErrorAction Stop
}
AfterAll { Remove-Module Hermes.PowerShell -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.PowerShell module contract' {
    It 'has a valid manifest' { { Test-ModuleManifest $script:Manifest -ErrorAction Stop } | Should -Not -Throw }
    It 'uses version 0.5.0' { (Test-ModuleManifest $script:Manifest).Version.ToString() | Should -Be '0.5.0' }
    It 'exports exactly six commands' { @(Get-Command -Module Hermes.PowerShell).Count | Should -Be 6 }
    It 'provides help for every command' { foreach($c in Get-Command -Module Hermes.PowerShell){(Get-Help $c.Name).Synopsis|Should -Not -BeNullOrEmpty} }
}

Describe 'Hermes PowerShell profile configuration' {
    It 'exists and validates' {
        Test-Path $script:ProfileConfig | Should -BeTrue
        $config=Import-PowerShellDataFile $script:ProfileConfig
        (Test-HermesPowerShellConfiguration $config).IsValid | Should -BeTrue
    }
    It 'rejects empty modules' { (Test-HermesPowerShellConfiguration @{Modules=@()}).IsValid | Should -BeFalse }
    It 'rejects unsupported modules' { (Test-HermesPowerShellConfiguration @{Modules=@('Hermes.Unknown')}).IsValid | Should -BeFalse }
}

Describe 'PowerShell profile lifecycle' {
    BeforeEach {
        $script:TestProfile = Join-Path $TestDrive 'Microsoft.PowerShell_profile.ps1'
        $script:Config = @{ Modules=@('Hermes.Common','Hermes.Desktop') }
        Remove-Item `
            -LiteralPath $script:TestProfile `
            -Force `
            -ErrorAction SilentlyContinue
    }
    It 'reports an absent managed block' { (Get-HermesPowerShellSettings -ProfilePath $script:TestProfile).ManagedBlock | Should -Be 'Absent' }
    It 'handles an existing zero-byte profile' {
        New-Item -ItemType File -Path $script:TestProfile -Force | Out-Null

        { Get-HermesPowerShellSettings -ProfilePath $script:TestProfile } |
            Should -Not -Throw

        (Get-HermesPowerShellSettings -ProfilePath $script:TestProfile).ManagedBlock |
            Should -Be 'Absent'

        {
            Backup-HermesPowerShellSettings `
                -ProfilePath $script:TestProfile `
                -BackupDirectory $TestDrive
        } | Should -Not -Throw
    }
    It 'supports WhatIf without creating a profile' {
        Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -WhatIf
        Test-Path $script:TestProfile | Should -BeFalse
    }
    It 'installs and verifies the managed block' {
        $result=Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false
        $result.Changed | Should -BeTrue
        (Test-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile).IsCompliant | Should -BeTrue
    }
    It 'creates a missing nested profile directory' {
        $nestedProfile = Join-Path $TestDrive 'OneDrive\Documents\PowerShell\profile.ps1'

        Set-HermesPowerShellSettings `
            -Configuration $script:Config `
            -ProfilePath $nestedProfile `
            -SkipBackup `
            -Confirm:$false |
            Out-Null

        Test-Path -LiteralPath $nestedProfile -PathType Leaf | Should -BeTrue
    }
    It 'preserves unrelated profile content' {
        Set-Content $script:TestProfile "`$customValue = 'keep-me'"
        Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false | Out-Null
        Get-Content $script:TestProfile -Raw | Should -Match 'keep-me'
    }
    It 'is idempotent' {
        Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false | Out-Null
        (Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false).Changed | Should -BeFalse
    }
    It 'replaces an existing managed block without duplication' {
        Set-HermesPowerShellSettings -Configuration $script:Config -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false | Out-Null
        Set-HermesPowerShellSettings -Configuration @{Modules=@('Hermes.Common')} -ProfilePath $script:TestProfile -SkipBackup -Confirm:$false | Out-Null
        ([regex]::Matches((Get-Content $script:TestProfile -Raw),'>>> Project Hermes managed profile >>>')).Count | Should -Be 1
    }
}
