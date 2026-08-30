local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.adjust_window_size_when_changing_font_size = false

-- Removing the tab bar and borders
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = false
config.window_decorations = "RESIZE" -- Removes the top title bar

-- Split configuration to keep only a thin divider line
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 1.0, -- Keeps the inactive pane at the same brightness as the active one
}
-- Not zero: picom rounds this window with a 12px radius (corner-radius in
-- picom.conf), and with no padding that radius bites into the first and last
-- glyph of the corner rows.
config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

-- The color scheme comes from the active rice theme (themes/theme-switcher.sh);
-- wezterm reloads automatically when the theme changes.
local theme_file = wezterm.home_dir .. '/.config/rice-theme/wezterm-theme.lua'
wezterm.add_to_config_reload_watch_list(theme_file)
wezterm.add_to_config_reload_watch_list(wezterm.home_dir .. '/.config/rice-theme/current')
local ok, theme = pcall(dofile, theme_file)
if ok and type(theme) == 'table' then
    config.color_scheme = theme.color_scheme
    config.colors = theme.colors
else
    -- Fallback when no theme has been applied yet
    config.color_scheme = 'Gruvbox Dark (Gogh)'
    config.colors = {
        background = "#241f31",
        foreground = "#9a9996",
        cursor_bg = "#ebdbb2",
        cursor_fg = "#171421",
        split = "#3d3846",
    }
end

-- "JetBrainsMono Nerd Font" first, not plain "JetBrains Mono": the patched
-- build is what carries the glyphs the rest of this setup uses (bar, rofi,
-- dunst), and without it every prompt/starship/eza icon inside the terminal
-- falls back to another font or renders as tofu.
config.font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
    "JetBrains Mono",
    "Symbols Nerd Font",
    "DejaVu Sans Mono",
    "monospace",
})
config.font_size = 10.0

config.window_background_opacity = 0.9
-- 1.0, not 0.3: there is no background image here, so the only thing a lower
-- value did was wash out everything that paints a cell background —
-- selections, `ls`/eza colours, search highlights, the tmux status line.
config.text_background_opacity = 1.0

config.enable_scroll_bar = false

config.keys = {
    { key = 'e', mods = 'ALT', action = wezterm.action.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = 'o', mods = 'ALT', action = wezterm.action.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentPane{ confirm = true } },
    { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config

