BeforeAll {
    $script:ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
    $script:ManifestPath = Join-Path $script:ModuleRoot 'Hermes.Common.psd1'
    $script:ExpectedCommands = @(
        'Export-HermesJson'
        'Get-HermesRegistryValue'
        'Import-HermesJson'
        'Remove-HermesRegistryValue'
        'Restart-HermesExplorer'
        'Set-HermesRegistryValue'
        'Test-HermesAdministrator'
        'Test-HermesOperatingSystem'
        'Test-HermesPowerShell'
        'Test-HermesRegistryPath'
        'Write-HermesError'
        'Write-HermesLog'
        'Write-HermesSuccess'
        'Write-HermesWarning'
    )

    Remove-Module Hermes.Common -Force -ErrorAction SilentlyContinue
    Import-Module $script:ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Hermes.Common -Force -ErrorAction SilentlyContinue
}

Describe 'Hermes.Common module contract' {
    It 'has a valid module manifest' {
        {
            Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        } | Should -Not -Throw
    }

    It 'uses version 0.1.0' {
        $Manifest = Test-ModuleManifest -Path $script:ManifestPath
        $Manifest.Version | Should -Be ([version]'0.1.0')
    }

    It 'imports successfully' {
        Get-Module -Name Hermes.Common | Should -Not -BeNullOrEmpty
    }

    It 'exports exactly the intended public commands' {
        $ActualCommands = @(
            Get-Command -Module Hermes.Common |
                Select-Object -ExpandProperty Name |
                Sort-Object
        )

        $ExpectedCommands = @($script:ExpectedCommands | Sort-Object)

        $ActualCommands.Count | Should -Be $ExpectedCommands.Count
        Compare-Object -ReferenceObject $ExpectedCommands -DifferenceObject $ActualCommands |
            Should -BeNullOrEmpty
    }

    It 'does not export aliases, cmdlets, or variables' {
        $Manifest = Test-ModuleManifest -Path $script:ManifestPath

        @($Manifest.ExportedAliases.Keys).Count | Should -Be 0
        @($Manifest.ExportedCmdlets.Keys).Count | Should -Be 0
        @($Manifest.ExportedVariables.Keys).Count | Should -Be 0
    }

    It 'provides comment-based help for every public command' {
        foreach ($CommandName in $script:ExpectedCommands) {
            $Help = Get-Help -Name $CommandName -ErrorAction Stop
            $Help.Synopsis | Should -Not -BeNullOrEmpty -Because "$CommandName requires a synopsis"
        }
    }
}

Describe 'Write-HermesLog' {
    It 'returns a standardized information entry' {
        $Entry = Write-HermesLog `
            -Message 'Hermes test message' `
            -Level Information `
            -NoConsole

        $Entry | Should -Match '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[INFORMATION\] Hermes test message$'
    }

    It 'supports every declared log level' -ForEach @(
        'Debug'
        'Information'
        'Success'
        'Warning'
        'Error'
    ) {
        $Entry = Write-HermesLog `
            -Message 'Level test' `
            -Level $_ `
            -NoConsole

        $Entry | Should -Match ('\[{0}\] Level test$' -f $_.ToUpperInvariant())
    }

    It 'creates a parent directory and appends UTF-8 log entries' {
        $LogPath = Join-Path $TestDrive 'nested\logs\hermes.log'

        Write-HermesLog `
            -Message 'First entry' `
            -Level Information `
            -LogPath $LogPath `
            -NoConsole |
            Out-Null

        Write-HermesLog `
            -Message 'Second entry' `
            -Level Success `
            -LogPath $LogPath `
            -NoConsole |
            Out-Null

        Test-Path -LiteralPath $LogPath -PathType Leaf | Should -BeTrue

        $Content = Get-Content -LiteralPath $LogPath -Raw -Encoding UTF8
        $Content | Should -Match 'First entry'
        $Content | Should -Match 'Second entry'
    }

    It 'rejects an empty message' {
        {
            Write-HermesLog -Message '' -NoConsole
        } | Should -Throw
    }
}

Describe 'Logging convenience commands' {
    It 'writes a success-level entry' {
        Write-HermesSuccess -Message 'Success test' -NoConsole |
            Should -Match '\[SUCCESS\] Success test$'
    }

    It 'writes a warning-level entry' {
        Write-HermesWarning -Message 'Warning test' -NoConsole |
            Should -Match '\[WARNING\] Warning test$'
    }

    It 'writes an error-level entry without throwing' {
        {
            $script:ErrorEntry = Write-HermesError -Message 'Error test' -NoConsole
        } | Should -Not -Throw

        $script:ErrorEntry | Should -Match '\[ERROR\] Error test$'
    }

    It 'can write convenience entries to a log file' {
        $LogPath = Join-Path $TestDrive 'convenience.log'

        Write-HermesSuccess -Message 'Saved success' -LogPath $LogPath -NoConsole |
            Out-Null

        Get-Content -LiteralPath $LogPath -Raw |
            Should -Match '\[SUCCESS\] Saved success'
    }
}

Describe 'Test-HermesPowerShell' {
    It 'accepts the current PowerShell version' {
        Test-HermesPowerShell -MinimumVersion $PSVersionTable.PSVersion |
            Should -BeTrue
    }

    It 'accepts the minimum supported version' {
        Test-HermesPowerShell -MinimumVersion ([version]'5.1') |
            Should -BeTrue
    }

    It 'rejects an unavailable future version' {
        Test-HermesPowerShell -MinimumVersion ([version]'99.0') |
            Should -BeFalse
    }
}

Describe 'Test-HermesOperatingSystem' {
    It 'identifies Windows' {
        Test-HermesOperatingSystem -OperatingSystem Windows |
            Should -BeTrue
    }

    It 'does not identify the current system as Linux' {
        Test-HermesOperatingSystem -OperatingSystem Linux |
            Should -BeFalse
    }

    It 'does not identify the current system as macOS' {
        Test-HermesOperatingSystem -OperatingSystem macOS |
            Should -BeFalse
    }

    It 'rejects unsupported platform names' {
        {
            Test-HermesOperatingSystem -OperatingSystem Solaris
        } | Should -Throw
    }
}

Describe 'Test-HermesAdministrator' {
    It 'returns a Boolean value' {
        Test-HermesAdministrator | Should -BeOfType [bool]
    }
}

Describe 'Hermes JSON helpers' {
    BeforeEach {
        $script:JsonPath = Join-Path `
            $TestDrive `
            ('nested\settings-{0}.json' -f ([guid]::NewGuid().ToString('N')))
        $script:TestObject = [pscustomobject]@{
            Name = 'Hermes'
            Version = '0.1.0'
            Enabled = $true
            Nested = [pscustomobject]@{
                Count = 3
            }
        }
    }

    It 'exports JSON and creates its parent directory' {
        $File = $script:TestObject |
            Export-HermesJson -Path $script:JsonPath

        $File | Should -BeOfType [System.IO.FileInfo]
        $File.FullName | Should -Be ([System.IO.Path]::GetFullPath($script:JsonPath))
        Test-Path -LiteralPath $script:JsonPath -PathType Leaf | Should -BeTrue
    }

    It 'imports exported JSON accurately' {
        $script:TestObject |
            Export-HermesJson -Path $script:JsonPath |
            Out-Null

        $Imported = Import-HermesJson -Path $script:JsonPath

        $Imported.Name | Should -Be 'Hermes'
        $Imported.Version | Should -Be '0.1.0'
        $Imported.Enabled | Should -BeTrue
        $Imported.Nested.Count | Should -Be 3
    }

    It 'refuses to overwrite an existing file without Force' {
        $script:TestObject |
            Export-HermesJson -Path $script:JsonPath |
            Out-Null

        {
            $script:TestObject |
                Export-HermesJson -Path $script:JsonPath
        } | Should -Throw '*Use -Force to overwrite*'
    }

    It 'overwrites an existing file with Force' {
        $script:TestObject |
            Export-HermesJson -Path $script:JsonPath |
            Out-Null

        $UpdatedObject = [pscustomobject]@{ Name = 'Updated' }

        $UpdatedObject |
            Export-HermesJson -Path $script:JsonPath -Force |
            Out-Null

        (Import-HermesJson -Path $script:JsonPath).Name |
            Should -Be 'Updated'
    }

    It 'does not create a file under WhatIf' {
        $script:TestObject |
            Export-HermesJson -Path $script:JsonPath -WhatIf |
            Should -BeNullOrEmpty

        Test-Path -LiteralPath $script:JsonPath |
            Should -BeFalse
    }

    It 'throws for a missing JSON file' {
        {
            Import-HermesJson -Path (Join-Path $TestDrive 'missing.json')
        } | Should -Throw '*does not exist*'
    }

    It 'throws for an empty JSON file' {
        $EmptyPath = Join-Path $TestDrive 'empty.json'
        Set-Content -LiteralPath $EmptyPath -Value '' -NoNewline

        {
            Import-HermesJson -Path $EmptyPath
        } | Should -Throw '*is empty*'
    }

    It 'throws for malformed JSON' {
        $InvalidPath = Join-Path $TestDrive 'invalid.json'
        Set-Content -LiteralPath $InvalidPath -Value '{ invalid json' -NoNewline

        {
            Import-HermesJson -Path $InvalidPath
        } | Should -Throw '*Failed to parse JSON*'
    }

    It 'imports JSON as a hashtable in PowerShell 6 or later' -Skip:($PSVersionTable.PSVersion.Major -lt 6) {
        $script:TestObject |
            Export-HermesJson -Path $script:JsonPath |
            Out-Null

        $Imported = Import-HermesJson -Path $script:JsonPath -AsHashtable

        $Imported | Should -BeOfType [hashtable]
        $Imported['Name'] | Should -Be 'Hermes'
    }
}

Describe 'Hermes Registry helpers' -Tag 'Windows' {
    BeforeEach {
        $script:RegistryPath = 'HKCU:\Software\ProjectHermes\Tests\Common-{0}' -f ([guid]::NewGuid().ToString('N'))
        $script:RegistryName = 'HermesTestValue'
    }

    AfterEach {
        Remove-Item `
            -LiteralPath $script:RegistryPath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    It 'returns false for a missing Registry path' {
        Test-HermesRegistryPath -Path $script:RegistryPath |
            Should -BeFalse
    }

    It 'creates a Registry path and DWord value when requested' {
        $Result = Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 1 `
            -Type DWord `
            -CreatePath

        $Result.Changed | Should -BeTrue
        $Result.Applied | Should -BeTrue
        Test-HermesRegistryPath -Path $script:RegistryPath | Should -BeTrue
        Get-HermesRegistryValue -Path $script:RegistryPath -Name $script:RegistryName |
            Should -Be 1
    }

    It 'is idempotent when a Registry value already matches' {
        Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 1 `
            -Type DWord `
            -CreatePath |
            Out-Null

        $Result = Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 1 `
            -Type DWord

        $Result.Changed | Should -BeFalse
        $Result.Applied | Should -BeFalse
    }

    It 'updates an existing Registry value' {
        Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 1 `
            -Type DWord `
            -CreatePath |
            Out-Null

        $Result = Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 2 `
            -Type DWord

        $Result.Changed | Should -BeTrue
        $Result.Applied | Should -BeTrue
        Get-HermesRegistryValue -Path $script:RegistryPath -Name $script:RegistryName |
            Should -Be 2
    }

    It 'requires CreatePath for a missing Registry key' {
        {
            Set-HermesRegistryValue `
                -Path $script:RegistryPath `
                -Name $script:RegistryName `
                -Value 1 `
                -Type DWord
        } | Should -Throw '*Use -CreatePath*'
    }

    It 'does not create a Registry path under WhatIf' {
        Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 1 `
            -Type DWord `
            -CreatePath `
            -WhatIf |
            Out-Null

        Test-Path -LiteralPath $script:RegistryPath |
            Should -BeFalse
    }

    It 'returns DefaultValue when a Registry value is missing' {
        New-Item -Path $script:RegistryPath -Force | Out-Null

        Get-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -DefaultValue 'missing' |
            Should -Be 'missing'
    }

    It 'throws for a missing Registry value when ThrowOnMissing is used' {
        New-Item -Path $script:RegistryPath -Force | Out-Null

        {
            Get-HermesRegistryValue `
                -Path $script:RegistryPath `
                -Name $script:RegistryName `
                -ThrowOnMissing
        } | Should -Throw '*could not be read*'
    }

    It 'removes an existing Registry value' {
        Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 'present' `
            -Type String `
            -CreatePath |
            Out-Null

        $Result = Remove-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName

        $Result.Existed | Should -BeTrue
        $Result.Removed | Should -BeTrue

        Get-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -DefaultValue 'missing' |
            Should -Be 'missing'
    }

    It 'handles a missing Registry value when IgnoreMissing is used' {
        $Result = Remove-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -IgnoreMissing

        $Result.Existed | Should -BeFalse
        $Result.Removed | Should -BeFalse
    }

    It 'does not remove a Registry value under WhatIf' {
        Set-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -Value 'present' `
            -Type String `
            -CreatePath |
            Out-Null

        $Result = Remove-HermesRegistryValue `
            -Path $script:RegistryPath `
            -Name $script:RegistryName `
            -WhatIf

        $Result.Existed | Should -BeTrue
        $Result.Removed | Should -BeFalse
        Get-HermesRegistryValue -Path $script:RegistryPath -Name $script:RegistryName |
            Should -Be 'present'
    }
}

Describe 'Restart-HermesExplorer' -Tag 'Windows' {
    It 'supports WhatIf without restarting Explorer' {
        $Before = @(Get-Process -Name explorer -ErrorAction SilentlyContinue).Id

        $Result = Restart-HermesExplorer -WhatIf

        $After = @(Get-Process -Name explorer -ErrorAction SilentlyContinue).Id

        $Result.Requested | Should -BeFalse
        $Result.Restarted | Should -BeFalse
        $Result.ProcessId | Should -BeNullOrEmpty
        Compare-Object -ReferenceObject $Before -DifferenceObject $After |
            Should -BeNullOrEmpty
    }

    It 'rejects an invalid timeout' {
        {
            Restart-HermesExplorer -TimeoutSeconds 0 -WhatIf
        } | Should -Throw
    }
}
