# Omarchy Windows-style desktop

A mouse-first Windows 11-inspired desktop built on **Omarchy and Hyprland**: floating windows, title-bar controls, a centered taskbar, Start menu, click-to-open system tray, familiar shortcuts, and optional TV/HDR controls.

This is the source snapshot of a working personal setup, shared so it can be backed up, recreated, and improved. It is **not a new compositor**, an official Windows theme, or a claim of complete Windows compatibility.

## What is included

- Floating, draggable and resizable windows; native and fallback minimize/maximize/close controls.
- Minimize/restore service with special-workspace bookkeeping; show desktop; taskbar application activation.
- Focus/stacking repairs, including returning floating windows behind a focused maximized app.
- Chrome activation for external links, and disabled cursor warping.
- Centered Windows-style application buttons, tooltips, window previews, app icons and context menus.
- Locked taskbar/tray placement. The tray drawer toggles on **click**, not hover.
- Start/search menu, desktop icons, action center, clock, settings panels and app-index generator.
- Windows-like keyboard shortcuts, Caps Lock configuration, terminal clipboard bindings.
- Voxtype clipboard/paste integration for Wayland and XWayland.
- Source for hyprbars, the native-minimize bridge, and the omarchy-windows native Aero Snap component.
- Notification center: toasts expire like Windows and land in a clock-triggered history + calendar flyout with Do not disturb.
- Settings app backed by real system state: GTK and terminal text size independent of taskbar/icons, HDR brightness, This PC, sound, network, Bluetooth, storage and native Omarchy settings, with search.
- Explorer-style Files: always-visible pasteable path bar, **Open in Terminal** and **Copy as path** right-click items; Windows Terminal-style copy/paste in foot.
- Taskbar groups windows per app with click-to-switch previews that close reliably while windows open and close.
- Wi-Fi, Bluetooth and sound flyouts pass network names, passwords and device IDs without a shell; the Wi-Fi password goes to NetworkManager on stdin, never in a command line.
- Optional 4K/60 Hz, scale-1.75 LG TV HDR profile and source-built HDR exposure slider that brightens every app uniformly.
- App launcher integrations and optional package installation instructions.

## Compatibility

Captured on **Omarchy 4.0.3 / Hyprland 0.56.2 / Quickshell 0.3.1**, Arch Linux x86-64. See `packages.txt` for the snapshot. Start from an existing working Omarchy installation; this is not an Arch installer.

**Native plugins depend on the compositor ABI.** The installer refuses native builds against another Hyprland version. A matching version string is not sufficient if downstream source differs: test in a nested compositor before loading into a desktop. Never overwrite a loaded `.so`; installed filenames include a content hash. See [verification](docs/VERIFICATION.md).

## Install

Read the scripts first. Running without `--apply` prints a plan and changes nothing.

```sh
git clone https://github.com/xsploit/omarchy-windows-desktop.git
cd omarchy-windows-desktop
python3 install.py
```

Install build dependencies from Arch (Hyprland's matching headers and its dependencies must already be available):

```sh
sudo pacman -S --needed base-devel pkgconf qt6-base qt6-declarative qt6-svg \
  python git wl-clipboard wtype jq curl glslang nautilus foot papirus-icon-theme
```

Optional apps: run `bash install-apps.sh` after reviewing its package list. It installs Chrome/Voxtype through `yay`, Discord, OBS, Steam, Wine and Stremio. Steam requires Arch's multilib repository. Package names and available versions may change; no proprietary app binaries are committed.

```sh
python3 install.py --apply --build-native
systemctl --user daemon-reload
systemctl --user enable desktop-windows.service
# Disable an old duplicate dock if you have one:
systemctl --user disable --now omarchy-app-dock.service
# Refresh the app icon catalog:
~/.local/bin/omarchy-undercover-scan-apps
update-desktop-database ~/.local/share/applications
```

Then **log out and back in**. Existing monitor settings are preserved by default. The rest of the listed desktop configuration is overlaid with a dated backup. Never install over a session with unsaved work without reviewing the changes. `--activate` is an explicit optional immediate reload/restart path; a fresh login is preferable.

The local plugin IDs retain `subsect.*` and `undercover.*` as stable identifiers. No corresponding Linux username is required: `@HOME@` templates are rewritten to the installing user's home. Home paths containing spaces or shell punctuation are rejected because some upstream launch commands are shell strings.

## Restore your previous configuration

Each install prints its backup directory, containing an exact list of changed files. Rollback restores previous files/symlinks and removes newly installed files:

```sh
python3 restore.py ~/.local/state/omarchy-windows-desktop/backups/TIMESTAMP
systemctl --user daemon-reload
```

Log out/in afterward. The rollback restores files; it does not uninstall optional packages or undo manual service enable/disable commands. It does not delete unrelated user files.

## Shortcuts

| Shortcut | Action |
|---|---|
| Alt+F4 | Close window |
| Alt+Tab | Existing Omarchy window switcher |
| Win+E | Files |
| Win+I | Settings |
| Win+S | Start/search |
| Win+D | Show/restore desktop |
| Win+Up / Down | Maximize / restore or minimize |
| Win+Left / Right | Snap |
| Win+Shift+S | Screenshot region to clipboard |
| Win+V | Clipboard history |
| Win+H | Voxtype dictation toggle |
| Ctrl+Shift+Esc | Task Manager launcher |
| Ctrl+Alt+Delete | System menu |
| Win+L | Lock |

Normal application Ctrl+C/Ctrl+V remain application behavior. In the terminal Ctrl+C still interrupts; Ctrl+Shift+C/V and Ctrl+Insert/Shift+Insert handle the clipboard. This does not falsely remap Ctrl+C across terminal programs.

## Appearance and optional features

The taskbar and menus include their own Windows-style colors and icons. The captured palette is in `appearance/palette.json`. The original setup used [Windows Dark Mode by oldjobobo](https://github.com/oldjobobo/omarchy-windows-dark-mode-theme); that third-party theme and Windows wallpaper artwork are **not redistributed here**. A neutral, locally generated wallpaper is included. Bring your own background or install an appropriately licensed theme through Omarchy. Existing Omarchy application theming is retained.

[Applications and dictation](docs/APPLICATIONS.md) · [TV/HDR profile](profiles/lg-4k-hdr/README.md) · [Architecture and limitations](docs/ARCHITECTURE.md) · [Upstream credits](THIRD_PARTY.md)

## Privacy and scope

No browser cookies, profiles, passwords, recovery codes, account exports, personal recordings, chat histories, installed app inventories or runtime state are included. No Facebook/Instagram recovery changes are part of this desktop configuration. The microphone distortion investigation was unfinished; no speculative audio fix is shipped.

Oma/Jarvis remains a separate project; its account settings, services and credentials are not bundled. The optional voice indicator source is included but is not enabled by default. This installer does not stop running agents.

## License

Original additions and the combined distribution are GPL-3.0-or-later. Upstream files retain their respective notices and licenses; see `licenses/` and `THIRD_PARTY.md`. Product names and logos belong to their owners. This project is not affiliated with Microsoft, Meta, Google, Omarchy, or the credited upstream projects.
