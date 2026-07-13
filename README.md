# My i3wm setup for Zorin OS

![i3wm Overview](./assets/img/i3wm-overview.png)

My personal configuration for i3 (i3-gaps), with Picom, i3status-rs, WezTerm and Rofi. A single theme switcher keeps i3, Rofi, Dunst, WezTerm, i3status-rs, Eww and the lock screen synchronized across Dracula, Gruvbox and Catppuccin Mocha. The installer symlinks configuration files into `~/.config` and `~/.local/bin` by default, so the repository stays the single source of truth (use `--copy` for standalone copies).

The alternating split behavior is provided by the upstream project [olemartinorg/i3-alternating-layout](https://github.com/olemartinorg/i3-alternating-layout), which is now included here as a Git submodule in `i3wm/scripts/i3-alternating-layout`.

---

## Components

| Component            | Tool                                                    |
| -------------------- | --------------------------------------------------------|
| Window Manager       | [i3wm](https://i3wm.org/) (i3-gaps)                     |
| Terminal             | [WezTerm](https://wezterm.org/)                         |
| Status Bar           | [i3status-rs](https://github.com/greshake/i3status-rust)|
| Compositor           | [Picom](https://github.com/yshui/picom)                 |
| Launcher             | [Rofi](https://github.com/davatorium/rofi)              |
| Themes               | Dracula, Gruvbox Dark and Catppuccin Mocha               |
| Wallpaper            | [feh](https://feh.finalrewind.org/) (random slideshow)  |
| Screenshot           | [Flameshot](https://flameshot.org/) (Flatpak)           |
| Lock Screen          | [i3lock-color](https://github.com/Raymo111/i3lock-color)|
| Notifications / OSD  | Dunst                                                  |
| Optional dashboard   | Eww                                                    |
| Clipboard history    | Greenclip                                              |
| Network Notifications| nm-applet                                               |
| Font                 | [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)   |

---

## Quick Installation

Clone the repository with submodules, then run the installer:

```bash
git clone --recursive https://github.com/cleissonbarbosa/my-i3wm-config.git
cd my-i3wm-config
chmod +x install.sh
./install.sh
```

If you already cloned the repository without submodules, run:

```bash
git submodule update --init --recursive
```

Non-interactive mode with flags (examples):

```bash
# Apply everything and install dependencies (full default)
./install.sh --all --non-interactive

# Apply configs without dependencies
./install.sh --non-interactive --no-deps

# Copy files instead of symlinking (default is symlink)
./install.sh --non-interactive --no-deps --copy

# Customize directories
./install.sh --non-interactive --config-dir "$HOME/.config" --wallpaper-dir "$HOME/Pictures/desktop background"

# Install optional extras in non-interactive mode
./install.sh --all --non-interactive --with-gnome-settings --with-flameshot
```

### Dependencies

```bash
# i3 and utilities
sudo apt install git python3-i3ipc i3 xss-lock dex numlockx feh

# i3lock-color (required for the themed lock screen)
# The default i3lock does NOT support the customization options used in this config.
# Install i3lock-color: https://github.com/Raymo111/i3lock-color#installation

# Compositor
sudo apt install picom

# Terminal emulator
# Install WezTerm from the official instructions for your distro:
# https://wezterm.org/install/linux.html

# Launcher
sudo apt install rofi

# Status bar (i3status-rs)
# See: https://github.com/greshake/i3status-rust#installation

# Volume and media control (wpctl comes with WirePlumber/PipeWire)
sudo apt install wireplumber playerctl

# Notifications, history, calculator clipboard and lock-screen cache
sudo apt install dunst jq xclip imagemagick

# Brightness control
sudo apt install light

# Clipboard history (the installer downloads the static binary)
# https://github.com/erebe/greenclip/releases

# Focus flash, workspace save/restore and emoji picker
# The installer creates an isolated venv under ~/.local/share/my-i3wm-config.
sudo apt install python3-venv

# Optional control-center dashboard (Eww)
# Build/install Eww separately, then the installer applies eww/ to ~/.config/eww.
# Native build dependencies on Ubuntu/Zorin:
sudo apt install libgtk-3-dev libgtk-layer-shell-dev libdbusmenu-gtk3-dev
# https://elkowar.github.io/eww/

# Network
sudo apt install network-manager-gnome

# GNOME Settings (optional, for $mod+Shift+s)
sudo apt install gnome-control-center

# Screenshot (Flatpak)
flatpak install flathub org.flameshot.Flameshot

# Browsers
# Install Brave and/or Google Chrome manually

# Fonts (required for icons and text in the bar)
# The installer downloads JetBrainsMono Nerd Font to ~/.local/share/fonts automatically.
# Manual install: https://www.nerdfonts.com/font-downloads
```

### Applying the Configurations Manually

The installer symlinks everything for you, but the manual equivalent is:

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/cleissonbarbosa/my-i3wm-config.git
cd my-i3wm-config

# If needed later
git submodule update --init --recursive

# Symlink configuration files (repository stays the source of truth)
mkdir -p ~/.config/i3 ~/.config/i3status ~/.config/picom ~/.config/dunst \
  ~/.config/rofi ~/.config/flashfocus ~/.local/bin
ln -sn "$PWD/i3wm/config" ~/.config/i3/config
ln -sn "$PWD/i3wm/scripts" ~/.config/i3/scripts
ln -sn "$PWD/i3wm/i3status/config.toml" ~/.config/i3status/config.toml
ln -sn "$PWD/picom/picom.conf" ~/.config/picom/picom.conf
ln -sn "$PWD/wezterm/.wezterm.lua" ~/.wezterm.lua
ln -sn "$PWD/flashfocus/flashfocus.yml" ~/.config/flashfocus/flashfocus.yml
ln -sn "$PWD/eww" ~/.config/eww

# Rofi and desktop helper scripts (all executables live in ~/.local/bin)
ln -sn "$PWD/rofi/rofi_launcher.sh" ~/.local/bin/rofi_launcher.sh
ln -sn "$PWD/rofi/rofi_sudo_launcher.sh" ~/.local/bin/rofi_sudo_launcher.sh
ln -sn "$PWD/rofi/rofi-askpass" ~/.local/bin/rofi-askpass
ln -sn "$PWD/rofi/rofi_powermenu.sh" ~/.local/bin/rofi_powermenu.sh
ln -sn "$PWD/rofi/rofi_calc.sh" ~/.local/bin/rofi_calc.sh
ln -sn "$PWD/rofi/rofi_clipboard.sh" ~/.local/bin/rofi_clipboard.sh
ln -sn "$PWD/dunst/dunst-history.sh" ~/.local/bin/dunst-history.sh
ln -sn "$PWD/themes/theme-switcher.sh" ~/.local/bin/theme-switcher.sh

# Generate the active Rofi/Dunst/theme files (without restarting the session)
./themes/theme-switcher.sh dracula --no-reload
```

Reload i3 with `$mod+Shift+r`.

---

## WezTerm

The repository now includes my WezTerm config in `wezterm/.wezterm.lua`.

Highlights:

- no title bar or tab bar
- thin split line and zero padding
- palette loaded from the active desktop theme and reloaded automatically
- pane navigation with `Alt + Arrow keys`
- pane splitting with `Alt+e` and `Alt+o`
- pane close with `Alt+w`

The installer links this file to `~/.wezterm.lua` by default.

---

## Keyboard Shortcuts

> **Mod key** = `Super` (Windows key)

### General

| Shortcut           | Action                         |
| ------------------ | -------------------------------|
| `$mod + Return`    | Open terminal                  |
| `$mod + Shift+q`   | Close focused window           |
| `$mod + d`         | Open Rofi (launcher)           |
| `$mod + Shift+d`   | Open Rofi with sudo            |
| `$mod + p`         | Open power menu                |
| `$mod + Shift+v`   | Open clipboard history         |
| `$mod + equal`     | Open calculator                |
| `$mod + period`    | Open emoji picker              |
| `$mod + Shift+t`   | Select and apply a color theme |
| `$mod + o`         | Toggle the Eww dashboard       |
| `$mod + t`         | Toggle dropdown terminal       |
| `$mod + F9/F10`    | Save/restore current workspace |
| `$mod + Escape`    | Lock screen                    |
| `$mod + Shift+s`   | Open GNOME Settings            |
| `$mod + Shift+n`   | Re-show last notification      |
| `$mod + Shift+h`   | Notification history (rofi)    |
| `$mod + Shift+c`   | Reload i3 configuration        |
| `$mod + Shift+r`   | Restart i3 (preserve session)  |
| `$mod + Shift+e`   | Exit i3                        |

### Navigation

| Shortcut                  | Action                                 |
| ------------------------- | -------------------------------------- |
| `$mod + j/k/l/ç`          | Focus left/down/up/right               |
| `$mod + Arrows`           | Focus left/down/up/right               |
| `$mod + Shift + j/k/l/ç`  | Move window left/down/up/right         |
| `$mod + Shift + Arrows`   | Move window left/down/up/right         |
| `$mod + 1-9,0`            | Switch to workspace 1-10               |
| `$mod + Shift + 1-9,0`    | Move window to workspace 1-10          |
| `$mod + Tab`              | Back and forth between workspaces      |
| `$mod + Shift + minus`    | Move window to scratchpad              |
| `$mod + minus`            | Show/cycle scratchpad windows          |

### Layout

| Shortcut              | Action                         |
| --------------------- | ------------------------------ |
| `$mod + h`            | Split horizontal               |
| `$mod + v`            | Split vertical                 |
| `$mod + f`            | Fullscreen                     |
| `$mod + s`            | Layout stacking                |
| `$mod + w`            | Layout tabbed                  |
| `$mod + e`            | Layout toggle split            |
| `$mod + Shift+Space`  | Toggle tiling/floating         |
| `$mod + Space`        | Toggle focus tiling/floating   |
| `$mod + r`            | Resize mode                    |
| `$mod + Shift+g`      | Interactive gaps mode         |

### Applications

| Shortcut     | Action                |
| ------------ | --------------------- |
| `$mod + b`   | Open Brave Browser    |
| `$mod + c`   | Open Google Chrome    |
| `Print`      | Screenshot (Flameshot)|

### Media and Hardware

Volume is controlled with `wpctl` (WirePlumber/PipeWire), in 5% steps capped at 100%. Volume and brightness changes display a Dunst progress-bar OSD.

| Shortcut                 | Action                    |
| ------------------------ | ------------------------- |
| `XF86AudioRaiseVolume`   | Increase volume (+5%)     |
| `XF86AudioLowerVolume`   | Decrease volume (-5%)     |
| `XF86AudioMute`          | Mute/unmute               |
| `XF86AudioMicMute`       | Mute/unmute microphone    |
| `XF86AudioPlay`          | Play/Pause                |
| `XF86AudioNext`          | Next track                |
| `XF86AudioPrev`          | Previous track            |
| `XF86AudioStop`          | Stop playback             |
| `XF86MonBrightnessUp`    | Increase brightness (+5)  |
| `XF86MonBrightnessDown`  | Decrease brightness (-5)  |

---

## Monitor Setup

Dual-monitor setup with both at **1920x1080 @ 144Hz**, configured with a single `xrandr` call:

- **DP-0** — Left monitor (primary, with tray)
- **DP-4** — Right monitor

Workspaces are pinned to monitors: odd workspaces on DP-0, even ones on DP-4 (each falls back to the other output on single-monitor sessions).

> Adjust the output names (`DP-0`, `DP-4`) according to your hardware using `xrandr --query`.

---

## Status Bar (i3status-rs)

Position: **top** | Theme: **Dracula** | Icons: **material-nf** (Nerd Font glyphs, provided by JetBrainsMono Nerd Font)

### Configured Blocks

| Block         | Information                                      |
| ------------- | ------------------------------------------------ |
| `disk_space`  | Available space on `/`                           |
| `memory`      | RAM usage (alert at 70%, critical at 90%)        |
| `cpu`         | CPU utilization                                  |
| `nvidia_gpu`  | NVIDIA GPU usage and temperature                 |
| `net`         | Network speed (auto-detected interface)          |
| `time`        | Date and time (format `Mon 01-01-2026 14:30:00`) |
| `sound`       | Audio volume                                     |
| `weather`     | Current weather (via Met.no, auto-location)      |
| `menu`        | Power menu (Suspend / Shutdown / Restart)        |

---

## Picom (Compositor)

Note: I am using Picom v13 compiled locally — this version includes animation support that improves transitions and visual effects.

| Effect              | Configuration                        |
| ------------------- | ------------------------------------ |
| Animations          | Enabled                              |
| Backend             | glx                                  |
| Shadows             | Enabled (radius: 12px, opacity: 0.45)|
| Fading              | Enabled (delta: 4ms)                 |
| Inactive Opacity    | 99%                                  |
| Frame Opacity       | 98%                                  |
| Rounded Corners     | 12px                                 |
| Background Blur     | Disabled                             |
| VSync               | Enabled                              |

> All per-window behavior (shadow/corner exclusions, window-type opacity) lives in the unified `rules` block — since picom v12, legacy options like `wintypes` and `shadow-exclude` are ignored when `rules` is set.

---

## Wallpaper

The `wallpaper-slideshow.sh` script (in `~/.config/i3/scripts/`) uses feh to change the wallpaper every **30 seconds**, randomly selecting from the `~/Pictures/desktop background/` folder. It guards against duplicate instances and can be customized via the `WALLPAPER_DIR` and `WALLPAPER_INTERVAL` environment variables.

Place your wallpapers in this directory to activate the slideshow.

---

## Color themes

The bundled themes are `dracula`, `gruvbox` and `catppuccin` (Mocha). Open the selector with `$mod+Shift+t`, or apply one directly:

```bash
theme-switcher.sh catppuccin
theme-switcher.sh gruvbox
theme-switcher.sh dracula
```

The selected theme is recorded in `~/.config/rice-theme/current` and applied consistently to i3, Rofi, Dunst, WezTerm, i3status-rs, Eww and i3lock. Theme definitions live under `themes/<name>/`; adding another directory with the same set of files makes it available to the selector.

---

## Lock Screen (i3lock-color)

> **Important:** The lock screen uses [i3lock-color](https://github.com/Raymo111/i3lock-color), which is a fork of i3lock with support for visual customization. The default `i3lock` **does not** support the color, blur, clock, and indicator options used in this configuration.

The i3lock-color invocation lives in a single script (`~/.config/i3/scripts/lock-screen.sh`) shared by xss-lock (suspend / `loginctl lock-session`) and the `$mod+Escape` binding.

Configured features:

- colors inherited from the active desktop theme
- pre-rendered blurred background cache for instant locking, with live blur as fallback
- Clock with date and time
- Circular indicator (radius: 120px)
- JetBrainsMono Nerd Font
- Media and volume key passthrough

---

## Gallery

### Rofi Launcher

![Rofi](./assets/img/rofi.png)

### Games

![Games](./assets/img/games.png)

### Workflow

![Work](./assets/img/i3wm-overview2.png)

### Lock Screen

![Lock Screen](./assets/img/lock-screen.png)

### SPF

![SPF](./assets/img/spf.png)
