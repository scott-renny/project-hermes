@{
    SchemaVersion = '1.0'
    Name          = 'Project Hermes Base Workstation'
    Description   = 'Windows 11 engineering workstation baseline for Project Hermes v0.5.0.'

    Platform = @{
        OperatingSystem          = 'Windows 11'
        SupportedEditions        = @('Home', 'Pro')
        MinimumPowerShellVersion = '7.0'
    }

    Order = @(
        'Winget'
        'Windows'
        'Explorer'
        'Taskbar'
        'Desktop'
        'Terminal'
        'Git'
        'VSCode'
        'PowerToys'
        'PowerShell'
    )

    Components = @{
        Winget = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\winget\Hermes.Winget.psd1'
            ConfigurationPath = 'configs\winget\hermes-winget-base.psd1'
        }
        Windows = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\windows\Hermes.Windows.psd1'
            ConfigurationPath = 'configs\windows\hermes-visual-base.psd1'
        }
        Explorer = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\explorer\Hermes.Explorer.psd1'
            ConfigurationPath = 'configs\windows\hermes-explorer-base.psd1'
        }
        Taskbar = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\taskbar\Hermes.Taskbar.psd1'
            ConfigurationPath = 'configs\windows\hermes-taskbar-base.psd1'
        }
        Desktop = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\desktop\Hermes.Desktop.psd1'
            ConfigurationPath = 'configs\windows\hermes-desktop-base.psd1'
        }
        Terminal = @{
            Enabled           = $true
            Required          = $false
            ModulePath        = 'modules\workstation\terminal\Hermes.Terminal.psd1'
            ConfigurationPath = 'configs\terminal\hermes-terminal-base.psd1'
        }
        Git = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\git\Hermes.Git.psd1'
            ConfigurationPath = 'configs\git\hermes-git-base.psd1'
        }
        VSCode = @{
            Enabled           = $true
            Required          = $false
            ModulePath        = 'modules\workstation\vscode\Hermes.VSCode.psd1'
            ConfigurationPath = 'configs\vscode\hermes-vscode-base.psd1'
        }
        PowerToys = @{
            Enabled           = $true
            Required          = $false
            ModulePath        = 'modules\workstation\powertoys\Hermes.PowerToys.psd1'
            ConfigurationPath = 'configs\powertoys\hermes-powertoys-base.psd1'
        }
        PowerShell = @{
            Enabled           = $true
            Required          = $true
            ModulePath        = 'modules\workstation\powershell\Hermes.PowerShell.psd1'
            ConfigurationPath = 'configs\powershell\hermes-powershell-base.psd1'
        }
    }
}
