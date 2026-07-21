@{
    # Project Hermes curated Windhawk baseline.
    # This file documents the approved desktop-experience configuration.
    # Windhawk settings are applied through the Windhawk interface because
    # mod storage and schemas are controlled by Windhawk and individual mods.

    EnabledMods = @(
        @{
            Id       = 'windows-11-taskbar-styler'
            Name     = 'Windows 11 Taskbar Styler'
            Theme    = 'TranslucentTaskbar'
            Purpose  = 'Creates the dark translucent Hermes taskbar.'
            Required = $true
        }
        @{
            Id       = 'windows-11-start-menu-styler'
            Name     = 'Windows 11 Start Menu Styler'
            Theme    = 'TranslucentStartMenu'
            Purpose  = 'Creates the dark translucent Hermes Start menu.'
            Required = $true
        }
        @{
            Id       = 'windows-11-notification-center-styler'
            Name     = 'Windows 11 Notification Center Styler'
            Theme    = 'TranslucentShell'
            Purpose  = 'Styles Notification Center and Quick Settings.'
            Required = $true
        }
        @{
            Id       = 'windows-11-file-explorer-styler'
            Name     = 'Windows 11 File Explorer Styler'
            Theme    = 'Translucent Explorer11'
            Purpose  = 'Styles File Explorer to match the Hermes shell.'
            Required = $true
        }
        @{
            Id       = 'better-file-sizes-in-explorer-details'
            Name     = 'Better file sizes in Explorer details'
            Theme    = $null
            Purpose  = 'Improves file-size information without changing layout.'
            Required = $false
        }
        @{
            Id       = 'redirect-bing-search'
            Name     = 'Start Search Bing Redirector'
            Theme    = $null
            Purpose  = 'Redirects Start-menu web results to Brave Search.'
            Required = $false
            Settings = @{
                SearchEngine = 'Brave Search'
                Browser      = 'Windows default browser'
            }
        }
    )

    DisabledMods = @(
        @{
            Name   = 'Vertical Taskbar for Windows 11'
            Reason = 'Overrides the native bottom taskbar position managed by Hermes.Taskbar.'
        }
        @{
            Name   = 'Taskbar Fade'
            Reason = 'Can reduce readability and conflict with the approved taskbar styling.'
        }
        @{
            Name   = 'Taskbar height and icon size'
            Reason = 'Introduces an additional owner for taskbar geometry.'
        }
        @{
            Name   = 'Taskbar Auto-Hide Instant Show'
            Reason = 'Not required while the Hermes baseline keeps auto-hide disabled.'
        }
        @{
            Name   = 'Taskbar Clock Customization'
            Reason = 'Hermes.Taskbar already enables native clock seconds.'
        }
        @{
            Name   = 'Taskbar tray system icon tweaks'
            Reason = 'Deferred until the stable tray requirements are defined.'
        }
        @{
            Name   = 'Windows 11 Start Menu Power Buttons'
            Reason = 'Deferred because it can overlap with Start Menu Styler.'
        }
    )
}
