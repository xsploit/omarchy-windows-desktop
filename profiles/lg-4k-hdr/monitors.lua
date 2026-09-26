-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.75

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({
  output = "HDMI-A-1",
  mode = "3840x2160@60",
  position = "0x0",
  scale = omarchy_monitor_scale,
  bitdepth = 10,
  cm = "hdr",
  -- Nits that SDR white maps to before sdrbrightness multiplies it. Hyprland
  -- defaults to 80, which is the old sRGB paper-white spec and far dimmer than
  -- anything a TV expects; 203 is the ITU BT.2408 HDR reference white that
  -- Windows also uses as its SDR baseline in HDR mode.
  sdr_max_luminance = 203,
  sdrbrightness = 1.0,
  sdrsaturation = 0.98,
})

-- Sensible fallback for any additional display connected later.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
