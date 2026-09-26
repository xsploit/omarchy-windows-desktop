# Sources and attribution

This is a configuration/integration project, not sole authorship of the desktop shell.

| Component | Upstream | Snapshot / license |
|---|---|---|
| Omarchy shell and cloned bar/tray/notifications | https://github.com/omacom/omarchy | Installed package 4.0.3-1; MIT (`licenses/omarchy.txt`) |
| Undercover menus, panels and icons | https://github.com/MISTERNEGATIVE21/omarchy-undercover | `11ce0de7fe44954dc6d1b6433b5f777da083e391`; GPL-3.0-or-later |
| hyprbars | https://github.com/hyprwm/hyprland-plugins | `7644cecdb947060682891a0db2a0cdc5c0b9e704`; upstream BSD-style license included |
| Native Aero Snap | https://github.com/jwm3000/omarchy-windows | `1ac2450e4bdb86398064601f8ef968793c65fcd9`; MIT |
| Original optional theme | https://github.com/oldjobobo/omarchy-windows-dark-mode-theme | Not vendored; colors recorded separately as settings |

Selected upstream Undercover fixes through v5.7.2 (`92ddb66`) were merged by hand — argv-only Wi-Fi/Bluetooth/sound commands, plain-text scan-derived names, throttled volume sliders, flyouts closing before launching apps — without adopting its plugin renames or state paths.

Local changes include taskbar app lookup/focus, actual launcher icons, menus and desktop controls, locked placement, click-only tray expansion, the window helper, native-minimize bridge, HDR controls, dictation paste integration, and relocatable installation/rollback.

The full omarchy-windows service and hyprfloat are not installed by this snapshot; only the native snap component is included. Upstream dependency repositories are not nested into Git history. External applications and their license agreements are separate installations.
