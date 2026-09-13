-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
-- Keep Omarchy defaults, but omit its blanket block on native maximize.
require("default.hypr.helpers")
local desktop_original_window = o.window
o.window = function(match, rules)
  if match == ".*" and rules.suppress_event == "maximize" then return end
  -- Let browsers follow our floating desktop layout.
  if type(match) == "table" and match.tag == "chromium-based-browser" then
    rules.tile = nil
  end
  return desktop_original_window(match, rules)
end
require("default.hypr.omarchy")
o.window = desktop_original_window

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Desktop-style window management: new application windows open floating so
-- they can overlap and be moved/resized freely with the mouse.
hl.window_rule({
  name = "desktop-style-floating-windows",
  match = { class = ".+" },
  tile = false,
  float = true,
})

-- Opaque application windows for clear, conventional desktop readability.
o.window(".*", { opacity = "1.0 1.0" })


require("hypr.titlebars")

-- Oma is a transparent desktop orb, including on the Electron preview path.
hl.window_rule({
  name = "oma-transparent-orb",
  match = { title = "^Oma Voice$" },
  float = true,
  decorate = false,
  border_size = 0,
  rounding = 0,
  no_blur = true,
  no_shadow = true,
  no_dim = true,
  opaque = false,
  force_rgbx = false,
})

-- Mouse-accessible software HDR brightness control.
require("hypr.hdr-brightness")

-- External links should activate Chrome; retain the other app focus protection.
o.window("google-chrome", { focus_on_activate = true })
o.window("com\\.anthropic\\.Claude", { focus_on_activate = false })

-- Reversible trial: native edge snapping from omarchy-windows.
require("hypr.windows-snap-trial")
