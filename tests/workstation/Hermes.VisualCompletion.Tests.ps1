Describe 'Hermes visual-completion assets' {
    BeforeAll {
        $repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
        $launcherRoot = Join-Path $repositoryRoot 'assets\rainmeter\HermesLauncher'
        $launcherIni = Join-Path $launcherRoot 'HermesLauncher.ini'
        $launcherScript = Join-Path $launcherRoot 'Invoke-HermesLauncher.ps1'
        $launcherSettings = Join-Path $launcherRoot 'HermesLauncher.settings.example.psd1'
        $lockScreenScript = Join-Path $repositoryRoot 'scripts\customization\Set-HermesLockScreen.ps1'
    }

    It 'includes the portable launcher resolver and settings' {
        $launcherScript | Should -Exist
        $launcherSettings | Should -Exist
        { Import-PowerShellDataFile -LiteralPath $launcherSettings } | Should -Not -Throw
    }

    It 'routes every launcher click through the resolver' {
        $content = Get-Content -LiteralPath $launcherIni -Raw
        $actions = [regex]::Matches($content, '(?m)^LeftMouseUpAction=(.+)$')
        $actions.Count | Should -BeGreaterThan 30
        @($actions | Where-Object { $_.Groups[1].Value -notmatch 'Invoke-HermesLauncher\.ps1' }).Count | Should -Be 0
    }

    It 'forces the launcher to accept mouse input on refresh' {
        $content = Get-Content -LiteralPath $launcherIni -Raw
        $content | Should -Match '\[!ClickThrough 0\]'
        $content | Should -Match '(?m)^MouseActionCursor=1$'
    }

    It 'defines every launcher action exposed by the skin' {
        $iniContent = Get-Content -LiteralPath $launcherIni -Raw
        $scriptContent = Get-Content -LiteralPath $launcherScript -Raw
        $actions = [regex]::Matches($iniContent, '"-Action"\s+"([^\"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        $missing = @($actions | Where-Object { $scriptContent -notmatch "'$([regex]::Escape($_))'\s*\{" })
        $missing | Should -BeNullOrEmpty
    }

    It 'opens installed desktop applications or their official download pages' {
        $content = Get-Content -LiteralPath $launcherScript -Raw
        $content | Should -Match 'function Start-HermesInstalledApp'

        foreach ($action in @(
            'discord'
            'slack'
            'teams'
            'telegram'
            'signal'
            'mail'
            'outlook'
            'matrix'
            'libreoffice'
            'notepad++'
            'obsidian'
            'vscode'
            'wireshark'
            'nmap'
            'bitwarden'
            '7zip'
            'everything'
        )) {
            $content | Should -Match "'$([regex]::Escape($action))'\s+\{ Start-HermesInstalledApp"
        }

        foreach ($downloadHost in @(
            'discord.com/download'
            'slack.com/downloads'
            'microsoft.com/microsoft-teams'
            'desktop.telegram.org'
            'signal.org/download'
            'thunderbird.net/download'
            'microsoft.com/microsoft-365/outlook'
            'element.io/download'
            'libreoffice.org/download'
            'notepad-plus-plus.org/downloads'
            'obsidian.md/download'
            'code.visualstudio.com/download'
            'wireshark.org/download'
            'nmap.org/download'
            'bitwarden.com/download'
            '7-zip.org/download'
            'voidtools.com/downloads'
        )) {
            $content | Should -Match ([regex]::Escape($downloadHost))
        }
    }

    It 'does not contain temporary worktree paths' {
        Get-Content -LiteralPath $launcherIni -Raw | Should -Not -Match 'Project-Hermes-v0[678]'
        Get-Content -LiteralPath $launcherScript -Raw | Should -Not -Match 'Documents\\Codex'
    }

    It 'includes a parseable guarded lock-screen installer' {
        $lockScreenScript | Should -Exist
        $tokens = $null
        $errors = $null
        [Management.Automation.Language.Parser]::ParseFile($lockScreenScript, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It 'uses the repository-owned gothic lock-screen artwork' {
        Get-Content -LiteralPath $lockScreenScript -Raw | Should -Match 'hermes-gothic-lockscreen-v2\.png'
        Join-Path $repositoryRoot 'assets\lockscreens\hermes-gothic-lockscreen-v2.png' | Should -Exist
    }

    It 'does not include the unstable cinematic lock experiment' {
        Join-Path $repositoryRoot 'scripts\customization\Invoke-HermesCinematicLock.ps1' | Should -Not -Exist
    }

    It 'loads only the consolidated gothic Rainmeter layout' {
        $installer = Get-Content -LiteralPath (Join-Path $repositoryRoot 'scripts\Install-HermesRainmeter.ps1') -Raw
        $installer | Should -Match "Name = 'HermesLauncher'; File = 'HermesLauncher.ini'"
        $installer | Should -Match "Name = 'HermesSidebar'; File = 'HermesSidebar.ini'"
        foreach ($legacyConfig in @('HermesClock', 'HermesPerformance', 'HermesAgenda', 'HermesNotes', 'HermesIdentity')) {
            $installer | Should -Match "'$([regex]::Escape($legacyConfig))'"
        }
    }}
