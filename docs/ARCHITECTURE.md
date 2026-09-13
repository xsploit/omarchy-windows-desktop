# Architecture and known limits

`home/` is an explicit allowlist of configuration and source, not a home-directory dump.

`desktop-windows.service` subscribes to Hyprland events and serves a private runtime socket. The `desktop-windows` CLI provides minimize/restore, focus, maximize, snapping, and show-desktop. Minimized geometry/session state stays in `$XDG_RUNTIME_DIR`; it is never published. Old queued focus events are checked atomically against the current window before raising anything. They must not restore, move, resize or refocus a window.

The locked bar keeps application buttons in the center and tray at the right, including after stale layout writes. `subsect.tray` is a user-owned clone; both horizontal and vertical drawers use click toggles. Bar/tray changes never modify `/usr/share/omarchy`.

hyprbars supplies controls to apps without their own decorations. Rules avoid duplicates for selected Chromium, GTK and other applications. The native-minimize plugin forwards XDG/XWayland minimize requests to the helper. New native plugin binaries are content addressed. A compositor update may require rebuilding or disabling these plugins.

Limitations:
- Hyprland still uses its own maximization, focus, modal and workspace semantics. Recent fixes passed selected overlap tests; they do not prove every app combination behaves exactly like Windows.
- The minimized special workspace is a custom implementation. Restarting the helper restores its saved windows via ExecStop; do so when this will not interrupt your work.
- Window previews depend on the compositor/Quickshell protocol and application behavior.
- CSD/SSD decisions are per app; new applications may require a rule. Native Wayland Electron is preferred. An old running XWayland Codex instance needed an outer-bar workaround until restarted.
- Keep Chrome `focus_on_activate=true` for external links. Other apps retain focus-stealing prevention.
- The inherited Undercover Wi-Fi/settings panels include upstream shell-based command construction. Avoid passing untrusted shell text to these panels; hardening that upstream code is separate work. Standard Omarchy/network tools remain available.
- HDR is output-specific software exposure, not a physical TV brightness control or a Windows-equivalent 0–100 scale.
- Caps Lock configuration is included; physical keyboard/IME behavior needs confirmation on each machine.

For new changes, edit your user overlays, back up first, then run `hyprctl reload` and `hyprctl configerrors`. Shell changes require plugin validation and, where hot reload does not apply them, `omarchy restart shell`.
