# Project Hermes Desktop Experience

This guide reproduces the approved Project Hermes visual desktop experience on Windows 11.

The desktop experience builds on the native configuration managed by the Project Hermes PowerShell modules. Windhawk supplies the visual shell layer, while Rainmeter supplies the performance panel. Windows remains the underlying operating system.

## Prerequisites

- Windows 11
- Project Hermes v0.5.0 or newer
- Windhawk
- Rainmeter 4.5.26 or newer
- The Project Hermes native Windows, Taskbar, and Desktop baselines applied

## Included assets

| Asset | Repository path | Purpose |
|---|---|---|
| Desktop wallpaper | `assets/wallpapers/hermes-wallpaper-concept-v2.png` | Primary Hermes desktop background |
| Lock-screen artwork | `assets/lockscreens/hermes-lockscreen-concept-v1.png` | Matching Windows lock screen |
| Rainmeter skin | `assets/rainmeter/HermesPerformance/HermesPerformance.ini` | Desktop performance panel |
| Windhawk baseline | `configs/windhawk/hermes-windhawk-base.psd1` | Approved mod and theme inventory |
| Transparent icon artwork | `assets/icons/png/` | Production PNG artwork with transparent backgrounds |
| Windows desktop icons | `assets/icons/ico/` | Multi-resolution Windows icon files |
| Editable icon sources | `assets/icons/source/` | Source and chroma-key artwork used to produce the final icons |

## Lock screen

Windows does not provide a dependable per-user automation interface for changing the lock-screen image across every Windows edition. Configure the approved asset through Windows Settings:

1. Open **Settings**.
2. Select **Personalization > Lock screen**.
3. Set **Personalize your lock screen** to **Picture**.
4. Select **Browse photos**.
5. Choose `assets/lockscreens/hermes-lockscreen-concept-v1.png` from the repository.
6. Press `Windows + L` to verify the result.

## Windhawk visual shell

Enable the following mods and select the listed integrated themes:

| Mod | Theme or setting |
|---|---|
| Windows 11 Taskbar Styler | `TranslucentTaskbar` |
| Windows 11 Start Menu Styler | `TranslucentStartMenu` |
| Windows 11 Notification Center Styler | `TranslucentShell` |
| Windows 11 File Explorer Styler | `Translucent Explorer11` |
| Better file sizes in Explorer details | Default settings |
| Start Search Bing Redirector | Brave Search |

Keep the conflict-prone mods listed under `DisabledMods` in `configs/windhawk/hermes-windhawk-base.psd1` disabled unless a future Hermes profile explicitly manages them.

## Rainmeter performance panel

Install the repository skin into the current user's Rainmeter skin directory:

```powershell
$repositorySkin = Join-Path `
    (Get-HermesRepositoryRoot) `
    'assets\rainmeter\HermesPerformance\HermesPerformance.ini'

$skinDirectory = Join-Path `
    ([Environment]::GetFolderPath('MyDocuments')) `
    'Rainmeter\Skins\HermesPerformance'

New-Item `
    -ItemType Directory `
    -Path $skinDirectory `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $repositorySkin `
    -Destination (Join-Path $skinDirectory 'HermesPerformance.ini') `
    -Force
```

Refresh Rainmeter, then load `HermesPerformance\HermesPerformance.ini`.

Place the panel in the upper-right corner. Set its position to **On desktop** and enable **Click through** after placement. The checked-in skin also applies desktop-layer positioning whenever it refreshes.

The initial panel uses native Rainmeter measures for:

- CPU utilization
- Physical-memory utilization
- System-disk utilization and free space
- Network download and upload rates
- Network activity graph
- System uptime
- Battery percentage
- Date and time

## Desktop navigation zone

Keep the following shortcuts vertically aligned along the upper-left edge:

1. This PC
2. Projects
3. Downloads
4. Recycle Bin

Keep all other working files off the desktop.

## Hermes desktop icons

Apply the coordinated graphite-and-cyan icon set after creating the desktop navigation shortcuts.

| Desktop item | Icon path |
|---|---|
| This PC | `assets/icons/ico/hermes-this-pc.ico` |
| Projects | `assets/icons/ico/hermes-projects.ico` |
| Downloads | `assets/icons/ico/hermes-downloads.ico` |
| Recycle Bin (empty) | `assets/icons/ico/hermes-recycle-bin.ico` |
| Recycle Bin (full) | `assets/icons/ico/hermes-recycle-bin-full.ico` |

Use **Personalization > Themes > Desktop icon settings** to assign the This PC and Recycle Bin icons. Assign both Recycle Bin states so Windows automatically displays the correct artwork as its contents change. Clear **Allow themes to change desktop icons** to prevent a theme from replacing the Hermes system icons.

For the Projects and Downloads shortcuts, open each shortcut's properties and select the corresponding file through **Shortcut > Change Icon**. Keep the repository in its configured location because Windows stores absolute paths to custom icon files.

The checked-in ICO files contain 256, 128, 96, 64, 48, 32, 24, and 16-pixel representations. The transparent PNG files are the production masters; the source directory retains the artwork needed to reproduce or revise the set.

## Taskbar command bar

Recommended pinned application order:

1. File Explorer
2. Firefox
3. Windows Terminal
4. Visual Studio Code
5. ChatGPT

Spotify and PowerToys may be pinned when they are used frequently. Windhawk should remain available from the system tray instead of occupying a taskbar position.

## Verification checklist

- The taskbar remains at the bottom and uses centered icons.
- Search is represented by an icon.
- Widgets remain disabled.
- Clock seconds remain enabled.
- The Start menu, notification surfaces, and File Explorer remain readable.
- Start-menu web results open Brave Search in the Windows default browser.
- The Rainmeter panel stays behind normal application windows.
- The Rainmeter panel remains readable against the Hermes wallpaper.
- `Windows + L` displays the concept-v1 lock-screen artwork.
- This PC, Projects, and Downloads display their assigned Hermes icons without visible background rectangles.
- Recycle Bin switches between the separate empty and full Hermes states.
- Desktop themes are not allowed to replace the Hermes system icons.

## Recovery

Disable the four Windhawk Styler mods to return the shell to its native appearance. Unload the Hermes Rainmeter skin to remove the performance panel. Use **Desktop icon settings > Restore Default** to restore the native This PC and Recycle Bin icons. Open the Projects and Downloads shortcut properties to select their default icons or remove the shortcuts. Use the existing Project Hermes restore commands for native Windows, Taskbar, and Desktop settings.
