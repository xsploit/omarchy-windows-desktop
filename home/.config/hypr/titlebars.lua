-- Official hyprbars revision 7644cec, built for installed Hyprland 0.56.2.
-- Skip this binary after a compositor upgrade until it has been rebuilt.
if hl.version():find("0.56.2", 1, true) then
  hl.plugin.load("@HOME@/.local/lib/hyprland/hyprbars-0.56.2.so")
  hl.plugin.load("@HOME@/.local/lib/hyprland/native-minimize-0.56.2-v2.so")
  if hl.plugin.hyprbars then
    hl.config({plugin = {hyprbars = {
      bar_height = 32,
      bar_color = "rgb(202535)",
      ["col.text"] = "rgb(f4f4f4)",
      bar_text_size = 13,
      bar_text_font = "sans-serif",
      bar_text_align = "left",
      bar_button_padding = 12,
      bar_padding = 12,
      on_double_click = "@HOME@/.local/bin/desktop-windows maximize",
    }}})
    -- Supply a fallback bar to ordinary windows, including newly installed apps.
    o.window(".*", {["hyprbars:no_bar"] = "false"})
    -- These apps draw their own controls. Keep embedded toolbars intact.
    o.window("(google-chrome.*|chromium.*|firefox|steam|com\\.anthropic\\.Claude|org\\.gnome\\..*)", {["hyprbars:no_bar"] = "true"})
    o.window("com\\.stremio\\.Stremio", {["hyprbars:no_bar"] = "true"})
    o.window("discord", {["hyprbars:no_bar"] = "true"})
    -- Keep the X11 drag workaround only until ChatGPT is reopened on Wayland.
    o.window({class="Chatgpt", xwayland=false}, {["hyprbars:no_bar"] = "true"})
    o.window({title="^Oma Voice$"}, {["hyprbars:no_bar"] = "true"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(202535)",fg_color="rgb(ffffff)",size=22,icon="×",action="hyprctl dispatch 'hl.dsp.window.close()'"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(202535)",fg_color="rgb(ffffff)",size=22,icon="□",action="@HOME@/.local/bin/desktop-windows maximize"})
    hl.plugin.hyprbars.add_button({bg_color="rgb(202535)",fg_color="rgb(ffffff)",size=22,icon="−",action="@HOME@/.local/bin/desktop-windows minimize"})
  end
end
