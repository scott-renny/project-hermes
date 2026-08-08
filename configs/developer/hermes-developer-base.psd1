@{
    Tools = @(
        @{
            Name             = 'Git'
            Command          = 'git'
            VersionArguments = @('--version')
            PackageId        = 'Git.Git'
            Source           = 'winget'
        }
        @{
            Name             = 'GitHub CLI'
            Command          = 'gh'
            VersionArguments = @('--version')
            PackageId        = 'GitHub.cli'
            Source           = 'winget'
        }
        @{
            Name             = 'PowerShell 7'
            Command          = 'pwsh'
            VersionArguments = @('--version')
            PackageId        = 'Microsoft.PowerShell'
            Source           = 'winget'
        }
        @{
            Name             = 'Visual Studio Code'
            Command          = 'code'
            VersionArguments = @('--version')
            PackageId        = 'Microsoft.VisualStudioCode'
            Source           = 'winget'
        }
        @{
            Name             = 'OpenSSH Client'
            Command          = 'ssh'
            VersionArguments = @('-V')
        }
    )

    VSCodeExtensions = @(
        'ms-vscode.powershell'
        'ms-vscode-remote.remote-ssh'
    )

    SshAgent = @{
        Required        = $true
        StartupType     = 'Automatic'
        MinimumLoadedKeys = 1
    }

    RemoteHosts = @(
        'coc-srv-01'
    )

    OptionalCapabilities = @(
        # WSL is detection-only because invoking the Windows launcher can offer
        # an installation on systems where the platform is not configured.
        @{ Name = 'WSL';     Command = 'wsl' }
        @{ Name = 'Docker';  Command = 'docker'; ProbeArguments = @('--version') }
        @{ Name = 'Python';  Command = 'python'; ProbeArguments = @('--version') }
        @{ Name = 'Node.js'; Command = 'node'; ProbeArguments = @('--version') }
        @{ Name = '.NET';    Command = 'dotnet'; ProbeArguments = @('--version') }
    )
}
