BeforeDiscovery {
    $repositoryRoot = Split-Path `
        (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) `
        -Parent
    $manifestPath = Join-Path $repositoryRoot `
        'modules\operations\maintenance\Hermes.Maintenance.psd1'

    Import-Module $manifestPath -Force
}
BeforeAll {
    $script:RepositoryRoot = Split-Path `
        (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) `
        -Parent
    $script:ManifestPath = Join-Path $script:RepositoryRoot `
        'modules\operations\maintenance\Hermes.Maintenance.psd1'
    $script:ConfigurationPath = Join-Path $script:RepositoryRoot `
        'configs\maintenance\hermes-maintenance-base.psd1'

    Import-Module $script:ManifestPath -Force
    $script:Configuration = Import-PowerShellDataFile $script:ConfigurationPath
}

AfterAll {
    Remove-Module Hermes.Maintenance -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Maintenance module contract' {
    It 'has a valid manifest' {
        { Test-ModuleManifest $script:ManifestPath -ErrorAction Stop } |
            Should -Not -Throw
    }

    It 'uses version 0.8.0' {
        (Test-ModuleManifest $script:ManifestPath).Version.ToString() |
            Should -Be '0.8.0'
    }

    It 'exports exactly five commands' {
        @(Get-Command -Module Hermes.Maintenance).Count | Should -Be 5
    }

    It 'provides help for every public command' {
        foreach ($command in Get-Command -Module Hermes.Maintenance) {
            (Get-Help $command.Name).Synopsis | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Hermes maintenance configuration' {
    It 'exists and validates' {
        Test-Path $script:ConfigurationPath | Should -BeTrue
        (Test-HermesMaintenanceConfiguration $script:Configuration).IsValid |
            Should -BeTrue
    }

    It 'rejects unsupported settings' {
        $result = Test-HermesMaintenanceConfiguration @{
            SchemaVersion = '1.0'
            ProfilePath = 'profile.psd1'
            BackupPolicy = @{RootPath='backups';MaximumAgeDays=30;MinimumPerModule=1}
            Reporting = @{OutputDirectory='reports';Formats=@('Json')}
            Unsupported = $true
        }
        $result.IsValid | Should -BeFalse
    }

    It 'rejects unsupported report formats' {
        $configuration = $script:Configuration.Clone()
        $configuration.Reporting = $script:Configuration.Reporting.Clone()
        $configuration.Reporting.Formats = @('Xml')
        (Test-HermesMaintenanceConfiguration $configuration).IsValid |
            Should -BeFalse
    }
}

Describe 'Maintenance audit result normalization' {
    InModuleScope Hermes.Maintenance {
        It 'treats a missing Differences property as no differences' {
            $result = [pscustomobject]@{IsCompliant=$true}

            Get-HermesValue $result 'Differences' | Should -BeNullOrEmpty
            @(ConvertTo-HermesDifferenceList `
                (Get-HermesValue $result 'Differences')).Count |
                Should -Be 0
        }

        It 'preserves one difference as a one-item list' {
            $difference = [pscustomobject]@{
                Setting='Widgets';Expected='Disabled';Actual='NotConfigured'
            }

            $normalized = ConvertTo-HermesDifferenceList $difference

            @($normalized).Count | Should -Be 1
            $normalized[0].Setting | Should -Be 'Widgets'
        }

        It 'preserves multiple differences without nesting them' {
            $differences = @(
                [pscustomobject]@{Setting='One'}
                [pscustomobject]@{Setting='Two'}
            )

            $normalized = ConvertTo-HermesDifferenceList $differences

            @($normalized).Count | Should -Be 2
            @($normalized.Setting) | Should -Be @('One','Two')
        }
    }
}

Describe 'Maintenance report lifecycle' {
    BeforeEach {
        $script:Audit = [pscustomobject]@{
            IsCompliant=$true
            Components=@(
                [pscustomobject]@{
                    Component='Git';Required=$true;Status='Compliant'
                    DifferenceCount=0
                }
            )
        }
        $script:Backup = [pscustomobject]@{
            IsHealthy=$true;BackupCount=1;ValidCount=1;StaleCount=0;Issues=@()
        }
    }

    It 'creates a healthy consolidated report' {
        $report = New-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Audit $script:Audit `
            -BackupHealth $script:Backup
        $report.OverallStatus | Should -Be 'Healthy'
        $report.ReportId | Should -Not -BeNullOrEmpty
    }

    It 'reports attention required when drift exists' {
        $script:Audit.IsCompliant = $false
        $report = New-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Audit $script:Audit `
            -BackupHealth $script:Backup
        $report.OverallStatus | Should -Be 'AttentionRequired'
    }

    It 'exports JSON and Markdown reports' {
        $report = New-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Audit $script:Audit `
            -BackupHealth $script:Backup
        $directory = Join-Path $TestDrive 'reports'
        $result = Export-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Report $report `
            -OutputDirectory $directory `
            -Confirm:$false
        @($result.Created).Count | Should -Be 2
        @($result.Created | Where-Object {$_ -like '*.json'}).Count | Should -Be 1
        @($result.Created | Where-Object {$_ -like '*.md'}).Count | Should -Be 1
    }

    It 'supports WhatIf without creating reports' {
        $report = New-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Audit $script:Audit `
            -BackupHealth $script:Backup
        $directory = Join-Path $TestDrive 'whatif'
        Export-HermesMaintenanceReport `
            -Configuration $script:Configuration `
            -Report $report `
            -OutputDirectory $directory `
            -WhatIf | Out-Null
        Test-Path $directory | Should -BeFalse
    }
}
