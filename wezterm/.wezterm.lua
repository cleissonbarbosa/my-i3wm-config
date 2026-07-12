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
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- VISUAL CONFIGURATION
config.color_scheme = 'Gruvbox Dark (Gogh)' -- Base para bater com seu cursor #ebdbb2
config.colors = {
    background = "#241f31",
    foreground = "#9a9996",
    cursor_bg = "#ebdbb2",
    cursor_fg = "#171421",
    -- Thin divider line between panes
    split = "#3d3846",
}

-- Font (Sans Bold 10)
config.font = wezterm.font_with_fallback({
    "JetBrains Mono",
    "DejaVu Sans Mono",
    "monospace",
})
config.font_size = 10.0

-- Transparency
config.window_background_opacity = 0.9
config.text_background_opacity = 0.3 -- Keeps the text readable over the image

-- Interface (No title bar and no scrollbar)
config.enable_scroll_bar = false

-- KEYBOARD SHORTCUTS
config.keys = {
    -- Vertical Split (Alt+E)
    { key = 'e', mods = 'ALT', action = wezterm.action.SplitVertical{ domain = 'CurrentPaneDomain' } },
    -- Horizontal Split (Alt+O)
    { key = 'o', mods = 'ALT', action = wezterm.action.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    -- Close Pane (Alt+W)
    { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentPane{ confirm = true } },
    -- Switch between panes (Alt + Arrows)
    { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config

