-- Change the default Omarchy look'n'feel.

-- Make floating windows snap naturally to monitor edges and other windows.
hl.config({
  general = {
    snap = {
      enabled = true,
      window_gap = 10,
      monitor_gap = 10,
      border_overlap = true,
      respect_gaps = true,
    },
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Mouse-first desktop: click to focus and grab window edges to resize.
hl.config({
  input = { follow_mouse = 2, float_switch_override_focus = 0, focus_on_close = 2 },
  misc = { focus_on_activate = false },
  cursor = { no_warps = true, persistent_warps = false, warp_on_change_workspace = 0, warp_on_toggle_special = 0 },
  general = { resize_on_border = true, extend_border_grab_area = 4 },
})

-- Soft window corners and shadows matching the Windows-style shell.
hl.config({ decoration = { rounding = 8, shadow = { enabled = true, range = 18, render_power = 3 } } })

-- Acrylic taskbar: Hyprland blurs whatever shows through the bar's tint.
-- The tint itself is [bar] background-alpha in ~/.config/omarchy/shell.toml.
-- Windows stay opaque (see hyprland.lua), so this costs nothing off the bar.
hl.config({
  decoration = {
    blur = {
      enabled = false,
      size = 6,
      passes = 3,
      noise = 0.02,
      -- Neutral on purpose. vibrancy boosts the saturation of whatever is
      -- behind the bar, which turns a warm patch of wallpaper into a maroon
      -- wash across half the taskbar. Windows 11 acrylic desaturates instead
      -- and leans on its tint, so these stay at the identity values.
      contrast = 1.0,
      brightness = 1.0,
      vibrancy = 0.0,
      vibrancy_darkness = 0.0,
      new_optimizations = true,
      popups = true,
    },
  },
})

hl.layer_rule({
  name = "acrylic-bar",
  match = { namespace = "omarchy-bar" },
  blur = true,
  ignore_alpha = 0.1,
})

-- Windows 11 flyouts share the taskbar's acrylic: blur what shows through the
-- notification center and the desktop context menu.
hl.layer_rule({
  name = "acrylic-flyouts",
  match = { namespace = "^win11-.*$" },
  blur = true,
  ignore_alpha = 0.1,
})

-- Flyouts rise from the taskbar the way Windows 11's do. The theme sets the
-- layer animation to a bare "slide", and Hyprland slides a layer surface in
-- from the edge it is anchored to — a full-screen-anchored flyout (the
-- notification center, the desktop menu) therefore dropped in from the top.
-- Pin the direction instead, and dismiss with a quick fade like Windows.
hl.animation({ leaf = "layersIn",  enabled = true, speed = 5, bezier = "myEase", style = "slide bottom" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 8, bezier = "myEase", style = "fade" })

-- Per-surface exceptions, matching where each one lives on a Windows desktop.
hl.layer_rule({ name = "win11-widgets-slide",  match = { namespace = "^win11-widgets$" },       animation = "slide left" })
hl.layer_rule({ name = "win11-toasts-slide",   match = { namespace = "^omarchy-notifications$" }, animation = "slide right" })
hl.layer_rule({ name = "win11-context-fade",   match = { namespace = "^win11-desktop-menu$" },  animation = "fade" })
