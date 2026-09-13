-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Oma voice control. Listening starts muted and toggles with this shortcut.
if o.cmd_present("omarchy-voice") then
  o.bind("SUPER + SHIFT + V", "Toggle Oma voice control", "omarchy-voice listen toggle")
end

-- Familiar desktop shortcuts. Alt+Tab retains the existing window switcher.
o.bind("ALT + F4", "Close window", hl.dsp.window.close())
o.bind("SUPER + E", "File Explorer", { omarchy = "nautilus" })
o.bind("SUPER + I", "Settings", "omarchy-menu toggle root")

-- Windows-style snipping shortcut (replaces Google Maps).
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot area to clipboard", "omarchy capture screenshot region copy")

-- Familiar Windows desktop shortcuts.
-- Replaces: Win+L layout toggle, Win+V universal paste, Win+S scratchpad,
-- Win+arrows directional focus, Ctrl+Alt+Delete close-all-windows.
local desktop_shortcuts = {
  { "SUPER + L", "Lock computer", "omarchy system lock" },
  { "SUPER + V", "Clipboard history", "omarchy-shell shell toggle omarchy.clipboard" },
  { "SUPER + S", "Start and search", "omarchy-win11-start" },
  { "SUPER + D", "Show or restore desktop", "@HOME@/.local/bin/desktop-windows show-desktop" },
  { "SUPER + UP", "Maximize window", "@HOME@/.local/bin/desktop-windows maximize-on" },
  { "SUPER + DOWN", "Restore or minimize window", "@HOME@/.local/bin/desktop-windows down" },
  { "SUPER + LEFT", "Snap window left", "@HOME@/.local/bin/desktop-windows snap-left" },
  { "SUPER + RIGHT", "Snap window right", "@HOME@/.local/bin/desktop-windows snap-right" },
  { "CTRL + SHIFT + ESCAPE", "Task Manager (Dave Plummer TMOG)", "@HOME@/.local/bin/tmog-task-manager" },
  { "CTRL + ALT + DELETE", "System menu", "omarchy menu summon system" },
}
for _, binding in ipairs(desktop_shortcuts) do
  hl.unbind(binding[1])
  o.bind(binding[1], binding[2], binding[3])
end

-- Windows-style toggle dictation (previously unused).
hl.unbind("SUPER + H")
o.bind("SUPER + H", "Start or stop voice dictation", "voxtype record toggle")
