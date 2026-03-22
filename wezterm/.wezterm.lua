local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.adjust_window_size_when_changing_font_size = false

-- Removendo a barra de abas e bordas
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = false
config.window_decorations = "RESIZE" -- Remove a barra de título superior

-- Configuração da divisão (Split) para ser apenas uma linha fina
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 1.0, -- Mantém o painel inativo com o mesmo brilho do ativo
}
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- Estilo da borda de divisão
config.colors = {
  -- Altere essa cor para combinar com o cinza da sua borda atual
  split = "#3d3846", 
}

-- CONFIGURAÇÃO VISUAL
config.color_scheme = 'Gruvbox Dark (Gnome Terminal)' -- Base para bater com seu cursor #ebdbb2
config.colors = {
    background = "#241f31",
    foreground = "#9a9996",
    cursor_bg = "#ebdbb2",
    cursor_fg = "#171421",
}

-- Fonte (Sans Bold 10)
config.font = wezterm.font_with_fallback({
    "JetBrains Mono",
    "DejaVu Sans Mono",
    "monospace",
})
config.font_size = 10.0

-- Imagem de Fundo e Transparência
config.window_background_image_hsb = {
    brightness = 0.1, -- Escurece a imagem para não atrapalhar o texto
    saturation = 1.0,
    hue = 1.0,
}
config.window_background_opacity = 0.9
config.text_background_opacity = 0.3 -- Deixa o texto legível sobre a imagem

-- Interface (Sem barra de título e sem scrollbar)
config.enable_scroll_bar = false

-- ATALHOS DE TECLADO
config.keys = {
    -- Split Vertical (Alt+E)
    { key = 'e', mods = 'ALT', action = wezterm.action.SplitVertical{ domain = 'CurrentPaneDomain' } },
    -- Split Horizontal (Alt+O)
    { key = 'o', mods = 'ALT', action = wezterm.action.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    -- Fechar Painel (Alt+W)
    { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentPane{ confirm = true } },
    -- Alternar entre painéis (Alt + Setas)
    { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
}

return config

