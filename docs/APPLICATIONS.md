# Optional applications

`install-apps.sh` is optional and separate from desktop installation. It uses Arch/AUR/Flathub, leaves prompts visible, and does not copy credentials or application data. Review third-party packages and their licenses as usual.

| Application | Integration / recreation |
|---|---|
| Chrome | AUR `google-chrome`; make `google-chrome.desktop` the default browser. Native focus rule is included. |
| Discord | Arch `discord`; native desktop entry and icons supported. Discord web is optional. |
| OBS | Arch `obs-studio`; select the desired microphone and PipeWire screen source yourself. |
| Steam | Arch `steam` after enabling multilib; no game library copied. |
| Stremio | User Flatpak `com.stremio.Stremio`; launcher included. |
| Notepad++ | Install official portable 8.9.8 under `~/.local/share/notepad-plus-plus/8.9.8/`; included Wine launcher uses a separate prefix. Source: https://notepad-plus-plus.org/downloads/v8.9.8/ |
| Task Manager | Captured optional TMOG 0.1.3 launcher expects `~/.local/share/tmog/0.1.3/bin/tmog-task-manager`. Binary is not redistributed. Until installed, launcher falls back to GNOME System Monitor, Mission Center or btop. |
| Claude desktop / CLI | Separate vendor installations. Launch Electron desktop with `--ozone-platform=wayland` where supported to avoid the old XWayland titlebar issue. No Claude binaries/account state copied. |
| Codex | Separate official CLI/desktop installation. Existing installed CLI snapshot was 0.153.4; this repo does not pin future updates or copy authentication. |
| Oma/Jarvis | Separate project and setup; optional source indicator included. Existing voice processes are not modified. |

## Dictation

Install Voxtype and download its `base.en` Whisper model using the installed version's model setup command (`voxtype setup --help`). Enable its daemon only after the model is ready:

```sh
systemctl --user enable --now voxtype.service
```

Win+H toggles recording. The committed config writes transcription to the clipboard; `voxtype-paste` uses Shift+Insert on Wayland or XTest Ctrl+V on XWayland. This avoids the observed simulated-typing output corruption. Check the selected microphone in your sound settings. No recordings or models are committed.

A theme icon pack is optional (`papirus-icon-theme`). Application icons are also discovered from desktop entries including user Flatpak exports. Regenerate with `omarchy-undercover-scan-apps` after installing applications. The generated `apps.json` stays local.
