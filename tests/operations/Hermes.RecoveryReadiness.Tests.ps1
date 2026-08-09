BeforeAll {
    $script:RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:CoreManifest = Join-Path $script:RepositoryRoot 'modules\core\Hermes.Core.psd1'
    $script:SampleJson = Join-Path $script:RepositoryRoot 'samples\maintenance\Hermes-Maintenance.sample.json'
    $script:SampleMarkdown = Join-Path $script:RepositoryRoot 'samples\maintenance\Hermes-Maintenance.sample.md'
}

Describe 'Hermes recovery readiness contract' {
    It 'round-trips a portable Hermes backup without changing workstation state' {
        Import-Module $script:CoreManifest -Force
        $backup = Write-HermesBackup `
            -ModuleName 'Hermes.RecoveryContract' `
            -Settings ([ordered]@{ Enabled = $true; Value = 'Portable' }) `
            -BackupDirectory (Join-Path $TestDrive 'backups')

        $document = Read-HermesBackup `
            -BackupPath $backup.BackupPath `
            -ExpectedModuleName 'Hermes.RecoveryContract'

        $document.SchemaVersion | Should -Be '1.0'
        $document.Settings.Enabled | Should -BeTrue
        $document.Settings.Value | Should -Be 'Portable'
    }

    It 'keeps every supported workstation restore command explicit and exported' {
        $contracts = [ordered]@{
            Desktop    = 'Restore-HermesDesktopSettings'
            Explorer   = 'Restore-HermesExplorerSettings'
            Git        = 'Restore-HermesGitSettings'
            PowerShell = 'Restore-HermesPowerShellSettings'
            PowerToys  = 'Restore-HermesPowerToysSettings'
            Taskbar    = 'Restore-HermesTaskbarSettings'
            Terminal   = 'Restore-HermesTerminalSettings'
            VSCode     = 'Restore-HermesVSCodeSettings'
            Windows    = 'Restore-HermesWindowsSettings'
        }

        foreach ($component in $contracts.Keys) {
            $folder = $component.ToLowerInvariant()
            $manifest = Join-Path $script:RepositoryRoot "modules\workstation\$folder\Hermes.$component.psd1"
            $metadata = Test-ModuleManifest -Path $manifest -ErrorAction Stop
            @($metadata.ExportedFunctions.Keys) | Should -Contain $contracts[$component]
        }
    }

    It 'documents WhatIf coverage for restore-capable modules' {
        $moduleFiles = Get-ChildItem `
            -Path (Join-Path $script:RepositoryRoot 'modules\workstation') `
            -Recurse -Filter 'Hermes.*.psm1'

        foreach ($moduleFile in $moduleFiles) {
            $content = Get-Content -LiteralPath $moduleFile.FullName -Raw
            if ($content -match 'function\s+Restore-Hermes') {
                $content | Should -Match '\$PSCmdlet\.ShouldProcess'
            }
        }
    }
}

Describe 'Hermes sanitized maintenance samples' {
    It 'includes parseable JSON with every report outcome represented' {
        $sample = Get-Content -LiteralPath $script:SampleJson -Raw | ConvertFrom-Json
        @($sample.workstationAudit.components.status) |
            Should -Be @('Compliant', 'Drifted', 'Unavailable', 'Error')
    }

    It 'contains no local user paths or live workstation identity' {
        $content = Get-Content -LiteralPath $script:SampleJson, $script:SampleMarkdown -Raw
        $content | Should -Not -Match '(?i)[A-Z]:\\Users\\'
        $content | Should -Not -Match '(?i)scott|COC-LT-01'
        $content | Should -Match 'REDACTED'
    }
}
