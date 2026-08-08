BeforeAll {
    $script:ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $script:ManifestPath = Join-Path $script:ModuleRoot 'Hermes.Developer.psd1'
    $script:RepositoryRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $script:ModuleRoot -Parent) -Parent) -Parent
    $script:ConfigurationPath = Join-Path $script:RepositoryRoot 'configs\developer\hermes-developer-base.psd1'

    Remove-Module Hermes.Developer -Force -ErrorAction SilentlyContinue
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
    $script:Configuration = Import-PowerShellDataFile $script:ConfigurationPath

    $script:CompliantInventory = [pscustomobject]@{
        CapturedAt = '2026-08-07T12:00:00-04:00'
        Tools = @($script:Configuration.Tools | ForEach-Object {[pscustomobject]@{Name=$_.Name;Command=$_.Command;Installed=$true;Version='test';Path="C:\Test\$($_.Command).exe";PackageId=$_.PackageId;Source=$_.Source}})
        VSCodeExtensions = @($script:Configuration.VSCodeExtensions)
        SshAgent = [pscustomobject]@{Exists=$true;Status='Running';StartupType='Automatic';LoadedKeys=@('256 SHA256:test hermes-test (ED25519)')}
        RemoteHosts = @('coc-srv-01')
        OptionalCapabilities = @()
    }
}

AfterAll { Remove-Module Hermes.Developer -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.Developer module contract' {
    It 'has a valid manifest' {{Test-ModuleManifest $script:ManifestPath -ErrorAction Stop} | Should -Not -Throw}
    It 'uses version 0.6.0' {(Test-ModuleManifest $script:ManifestPath).Version.ToString() | Should -Be '0.6.0'}
    It 'exports exactly the expected commands' {
        $expected=@('Export-HermesDeveloperInventory','Get-HermesDeveloperEnvironment','Set-HermesDeveloperEnvironment','Test-HermesDeveloperConfiguration','Test-HermesDeveloperEnvironment','Test-HermesRemoteHost')
        @(Get-Command -Module Hermes.Developer).Name | Sort-Object | Should -Be ($expected | Sort-Object)
    }
    It 'provides help for every public command' {foreach($command in Get-Command -Module Hermes.Developer){(Get-Help $command.Name).Synopsis | Should -Not -BeNullOrEmpty}}
}

Describe 'Hermes developer configuration' {
    It 'exists and validates' {Test-Path $script:ConfigurationPath | Should -BeTrue;(Test-HermesDeveloperConfiguration $script:Configuration).IsValid | Should -BeTrue}
    It 'rejects an empty configuration' {(Test-HermesDeveloperConfiguration @{}).IsValid | Should -BeFalse}
    It 'rejects unsupported top-level settings' {(Test-HermesDeveloperConfiguration @{Tools=$script:Configuration.Tools;Unknown=$true}).IsValid | Should -BeFalse}
    It 'rejects duplicate tool commands' {
        $invalid=@{Tools=@(@{Name='One';Command='git'},@{Name='Two';Command='git'})}
        (Test-HermesDeveloperConfiguration $invalid).IsValid | Should -BeFalse
    }
}

Describe 'Hermes developer compliance' {
    It 'reports compliance when every required component is present' {(Test-HermesDeveloperEnvironment $script:Configuration -Inventory $script:CompliantInventory).IsCompliant | Should -BeTrue}
    It 'reports a precise missing required tool' {
        $inventory=$script:CompliantInventory.PSObject.Copy();$inventory.Tools=@($inventory.Tools | Where-Object {$_.Command -ne 'git'})
        $result=Test-HermesDeveloperEnvironment $script:Configuration -Inventory $inventory
        $result.IsCompliant | Should -BeFalse
        @($result.Differences | Where-Object {$_.Category -eq 'Tool' -and $_.Name -eq 'Git'}).Count | Should -Be 1
    }
    It 'does not require optional capabilities' {
        $script:CompliantInventory.OptionalCapabilities=@([pscustomobject]@{Name='Docker';Command='docker';Detected=$false;Operational=$false;Status='NotInstalled';Path=$null})
        (Test-HermesDeveloperEnvironment $script:Configuration -Inventory $script:CompliantInventory).IsCompliant | Should -BeTrue
    }
    It 'supports WhatIf without installing missing components' {
        $inventory=$script:CompliantInventory.PSObject.Copy();$inventory.Tools=@($inventory.Tools | Where-Object {$_.Command -ne 'git'})
        $result=Set-HermesDeveloperEnvironment $script:Configuration -Inventory $inventory -WhatIf
        $result.Changed | Should -BeFalse
        @($result.PlannedActions).Count | Should -Be 1
    }
}

Describe 'Hermes developer inventory export' {
    It 'exports supplied inventory as JSON' {
        $path=Join-Path $TestDrive 'developer-inventory.json'
        Export-HermesDeveloperInventory -Path $path -Inventory $script:CompliantInventory -Confirm:$false | Out-Null
        Test-Path $path | Should -BeTrue
        (Get-Content $path -Raw | ConvertFrom-Json).SshAgent.Status | Should -Be 'Running'
    }
    It 'supports WhatIf without creating a file' {
        $path=Join-Path $TestDrive 'whatif.json'
        Export-HermesDeveloperInventory -Path $path -Inventory $script:CompliantInventory -WhatIf
        Test-Path $path | Should -BeFalse
    }
}
