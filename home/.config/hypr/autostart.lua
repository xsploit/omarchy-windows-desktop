-- Extra autostart processes.
-- The application dock is managed by omarchy-app-dock.service.

-- Refresh the HDR shader's monitor ID after each login.
hl.on("hyprland.start", function()
  hl.exec_cmd("@HOME@/.local/bin/hdr-brightness-control refresh")
end)

-- Night light: hyprsunset applies the schedule in hypr/hyprsunset.conf
-- (identity by day, 4000K from 20:00).
o.launch_on_start("hyprsunset")
