#!/usr/bin/env bash
# Optional app/dependency setup. Run yourself on Arch/Omarchy after reviewing.
set -euo pipefail
sudo pacman -S --needed base-devel git python qt6-base qt6-declarative qt6-svg \
  pkgconf pixman libdrm libinput systemd-libs wayland libxkbcommon \
  nautilus foot wl-clipboard wtype jq curl glslang papirus-icon-theme \
  discord obs-studio steam wine flatpak pavucontrol
if command -v yay >/dev/null; then
  yay -S --needed google-chrome voxtype
else
  printf '%s\n' 'Install google-chrome and voxtype with your AUR helper.'
fi
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub com.stremio.Stremio
if command -v google-chrome-stable >/dev/null; then
  env -u BROWSER xdg-settings set default-web-browser google-chrome.desktop
fi
printf '%s\n' 'For optional TMOG, Notepad++, Claude and Codex, see docs/APPLICATIONS.md.'
