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
