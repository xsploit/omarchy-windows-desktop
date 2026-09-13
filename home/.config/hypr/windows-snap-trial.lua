-- Omarchy Windows native snap component, built for this compositor ABI.
local disabled = io.open("@HOME@/.config/hypr/windows-snap-trial.disabled", "r")
if disabled then disabled:close(); return end
if hl.version():find("0.56.2", 1, true) then
  hl.plugin.load("@HOME@/.local/lib/hyprland/omarchy-windows-snap-0.56.2-7044989e22baf116.so")
  hl.config({plugin={omarchy_windows_snap={
    enabled=true, floating_mode_only=false, columns="2",
    edge_threshold=12, corner_ratio=0.25,
    preview_color="rgba(1e3a8a33)", preview_border_color="rgba(60cdffbd)",
    preview_border_size=2, preview_rounding=8, preview_blur=true,
    preview_animation_duration=150,
  }}})
end
