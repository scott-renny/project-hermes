BeforeDiscovery {
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $manifestPath = Join-Path $moduleRoot 'Hermes.Winget.psd1'

    Remove-Module Hermes.Winget -Force -ErrorAction SilentlyContinue
    Import-Module $manifestPath -Force -ErrorAction Stop
}

BeforeAll {
    $script:ModuleRoot=Split-Path $PSScriptRoot -Parent
    $script:ManifestPath=Join-Path $script:ModuleRoot 'Hermes.Winget.psd1'
    $script:RepositoryRoot=Split-Path (Split-Path (Split-Path $script:ModuleRoot -Parent) -Parent) -Parent
    $script:ConfigurationPath=Join-Path $script:RepositoryRoot 'configs\winget\hermes-winget-base.psd1'
    Remove-Module Hermes.Winget -Force -ErrorAction SilentlyContinue
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
    $script:Configuration=Import-PowerShellDataFile $script:ConfigurationPath
}
AfterAll { Remove-Module Hermes.Winget -Force -ErrorAction SilentlyContinue }

Describe 'Hermes.Winget module contract' {
    It 'has a valid manifest' {
        { Test-ModuleManifest $script:ManifestPath -ErrorAction Stop }|Should -Not -Throw
    }
    It 'uses version 0.5.0' {
        (Test-ModuleManifest $script:ManifestPath).Version.ToString()|Should -Be '0.5.0'
    }
    It 'exports exactly six commands' {
        @(Get-Command -Module Hermes.Winget).Count|Should -Be 6
    }
    It 'provides help for every command' {
        foreach($command in Get-Command -Module Hermes.Winget){
            (Get-Help $command.Name).Synopsis|Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes WinGet configuration' {
    It 'exists and validates' {
        Test-Path $script:ConfigurationPath|Should -BeTrue
        (Test-HermesWingetConfiguration $script:Configuration).IsValid|Should -BeTrue
    }
    It 'contains Core and Customization profiles' {
        $script:Configuration.Profiles.Keys|Should -Contain 'Core'
        $script:Configuration.Profiles.Keys|Should -Contain 'Customization'
    }
    It 'rejects an empty configuration' {
        (Test-HermesWingetConfiguration @{}).IsValid|Should -BeFalse
    }
    It 'rejects unsupported package sources' {
        $invalid=@{Profiles=@{Core=@(@{Id='Example.Package';Source='invalid'})}}
        (Test-HermesWingetConfiguration $invalid).IsValid|Should -BeFalse
    }
    It 'rejects duplicate packages across profiles' {
        $invalid=@{Profiles=@{One=@(@{Id='Example.Package'});Two=@(@{Id='Example.Package'})}}
        (Test-HermesWingetConfiguration $invalid).IsValid|Should -BeFalse
    }
}

Describe 'Hermes package compliance' {
    BeforeAll {
        $script:SmallConfiguration=@{
            Profiles=@{
                Core=@(
                    @{Id='Git.Git';Source='winget'}
                    @{Id='GitHub.cli';Source='winget'}
                )
            }
        }
    }
    It 'reports compliance when all packages are installed' {
        $inventory=@(
            [pscustomobject]@{Id='Git.Git';Installed=$true}
            [pscustomobject]@{Id='GitHub.cli';Installed=$true}
        )
        (Test-HermesWingetPackages $script:SmallConfiguration -Inventory $inventory).IsCompliant|Should -BeTrue
    }
    It 'reports precise missing packages' {
        $inventory=@([pscustomobject]@{Id='Git.Git';Installed=$true})
        $result=Test-HermesWingetPackages $script:SmallConfiguration -Inventory $inventory
        $result.IsCompliant|Should -BeFalse
        @($result.Missing).Id|Should -Contain 'GitHub.cli'
    }
    It 'supports selecting one profile' {
        $configuration=@{Profiles=@{Core=@(@{Id='Git.Git'});Customization=@(@{Id='Microsoft.PowerToys'})}}
        $inventory=@([pscustomobject]@{Id='Git.Git';Installed=$true})
        (Test-HermesWingetPackages $configuration -Profile Core -Inventory $inventory).IsCompliant|Should -BeTrue
    }
}

Describe 'WinGet inventory export' {
    It 'exports supplied inventory as JSON' {
        $path=Join-Path $TestDrive 'inventory\winget.json'
        Export-HermesWingetInventory $path -Inventory @([pscustomobject]@{Id='Git.Git';Installed=$true})|Out-Null
        Test-Path $path|Should -BeTrue
        (Get-Content $path -Raw|ConvertFrom-Json).Id|Should -Be 'Git.Git'
    }
    It 'supports WhatIf without creating a file' {
        $path=Join-Path $TestDrive 'inventory\whatif.json'
        Export-HermesWingetInventory $path -Inventory @() -WhatIf
        Test-Path $path|Should -BeFalse
    }
}

Describe 'WinGet live command orchestration' {
    InModuleScope Hermes.Winget {
        BeforeEach {
            $script:LiveConfiguration=@{
                Profiles=@{
                    Core=@(
                        @{Id='Git.Git';Source='winget'}
                        @{Id='GitHub.cli';Source='winget'}
                    )
                }
            }
        }

        It 'audits every configured package when Profile is omitted' {
            Mock Invoke-HermesWinget {
                param([string[]]$Arguments)
                [pscustomobject]@{
                    ExitCode=0
                    Output=@('installed')
                    Text=($Arguments -join ' ')
                }
            }

            $packages=@(Get-HermesWingetPackages -Configuration $script:LiveConfiguration)

            $packages.Count|Should -Be 2
            $packages.Id|Should -Contain 'Git.Git'
            $packages.Id|Should -Contain 'GitHub.cli'
        }

        It 'supports WhatIf without invoking a WinGet install command' {
            Mock Invoke-HermesWinget {
                param([string[]]$Arguments)
                [pscustomobject]@{
                    ExitCode=1
                    Output=@('No installed package found')
                    Text='No installed package found'
                }
            }

            $result=Install-HermesWingetPackages `
                -Configuration $script:LiveConfiguration `
                -WhatIf

            $result.Changed|Should -BeFalse
            @($result.Installed).Count|Should -Be 0
            $result.Verification.IsCompliant|Should -BeFalse
            Should -Invoke Invoke-HermesWinget `
                -Times 0 `
                -ParameterFilter { $Arguments[0] -eq 'install' }
        }
    }
}
