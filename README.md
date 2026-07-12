# My i3wm setup for Zorin OS

![i3wm Overview](./assets/img/i3wm-overview.png)

My personal configuration for i3 (i3-gaps). I use the Dracula theme, Picom as a compositor, i3status-rs for the status bar, and Rofi as a launcher. The installer symlinks the configuration files into `~/.config` and `~/.local/bin` by default, so the repository stays the single source of truth (use `--copy` for standalone copies).

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
| Theme                | [Dracula](https://draculatheme.com/)                    |
| Wallpaper            | [feh](https://feh.finalrewind.org/) (random slideshow)  |
| Screenshot           | [Flameshot](https://flameshot.org/) (Flatpak)           |
| Lock Screen          | [i3lock-color](https://github.com/Raymo111/i3lock-color)|
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

# i3lock-color (required for Dracula-themed lock screen)
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

# Notification history script
sudo apt install jq

# Brightness control
sudo apt install light

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
mkdir -p ~/.config/i3 ~/.config/i3status ~/.config/picom ~/.config/dunst ~/.config/rofi ~/.local/bin
ln -sn "$PWD/i3wm/config" ~/.config/i3/config
ln -sn "$PWD/i3wm/scripts" ~/.config/i3/scripts
ln -sn "$PWD/i3wm/i3status/config.toml" ~/.config/i3status/config.toml
ln -sn "$PWD/picom/picom.conf" ~/.config/picom/picom.conf
ln -sn "$PWD/dunst/dunstrc" ~/.config/dunst/dunstrc
ln -sn "$PWD/wezterm/.wezterm.lua" ~/.wezterm.lua

# Rofi theme and scripts (all executables live in ~/.local/bin)
ln -sn "$PWD/rofi/dracula.rasi" ~/.config/rofi/dracula.rasi
ln -sn "$PWD/rofi/rofi_launcher.sh" ~/.local/bin/rofi_launcher.sh
ln -sn "$PWD/rofi/rofi_sudo_launcher.sh" ~/.local/bin/rofi_sudo_launcher.sh
ln -sn "$PWD/rofi/rofi-askpass" ~/.local/bin/rofi-askpass
ln -sn "$PWD/dunst/dunst-history.sh" ~/.local/bin/dunst-history.sh
```

Reload i3 with `$mod+Shift+r`.

---

## WezTerm

The repository now includes my WezTerm config in `wezterm/.wezterm.lua`.

Highlights:

- no title bar or tab bar
- thin split line and zero padding
- Gruvbox-based palette adapted to match the desktop colors
- pane navigation with `Alt + Arrow keys`
- pane splitting with `Alt+e` and `Alt+o`
- pane close with `Alt+w`

The installer copies this file to `~/.wezterm.lua`.

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

### Applications

| Shortcut     | Action                |
| ------------ | --------------------- |
| `$mod + b`   | Open Brave Browser    |
| `$mod + c`   | Open Google Chrome    |
| `Print`      | Screenshot (Flameshot)|

### Media and Hardware

Volume is controlled with `wpctl` (WirePlumber/PipeWire), in 5% steps capped at 100%.

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

## Color Theme (Dracula)

Colors are defined as **variables in the i3 config**, making maintenance and consistency easier:

- `$backgroundColor` = ![#282a36](https://placehold.co/15x15/282a36/282a36) `#282a36`
- `$foreground` = ![#f8f8f2](https://placehold.co/15x15/f8f8f2/f8f8f2) `#f8f8f2`
- `$selection` = ![#44475a](https://placehold.co/15x15/44475a/44475a) `#44475a`
- `$comment` = ![#6272a4](https://placehold.co/15x15/6272a4/6272a4) `#6272a4`
- `$red` = ![#ff5555](https://placehold.co/15x15/ff5555/ff5555) `#ff5555`
- `$green` = ![#50fa7b](https://placehold.co/15x15/50fa7b/50fa7b) `#50fa7b`
- `$yellow` = ![#f1fa8c](https://placehold.co/15x15/f1fa8c/f1fa8c) `#f1fa8c`
- `$orange` = ![#ffb86c](https://placehold.co/15x15/ffb86c/ffb86c) `#ffb86c`
- `$magenta` = ![#ff79c6](https://placehold.co/15x15/ff79c6/ff79c6) `#ff79c6`
- `$cyan` = ![#8be9fd](https://placehold.co/15x15/8be9fd/8be9fd) `#8be9fd`
- `$blue` = ![#6272a4](https://placehold.co/15x15/6272a4/6272a4) `#6272a4`

Applied consistently in: i3wm (borders, bar, i3lock), Rofi, and i3status-rs.

---

## Lock Screen (i3lock-color)

> **Important:** The lock screen uses [i3lock-color](https://github.com/Raymo111/i3lock-color), which is a fork of i3lock with support for visual customization. The default `i3lock` **does not** support the color, blur, clock, and indicator options used in this configuration.

The i3lock-color invocation lives in a single script (`~/.config/i3/scripts/lock-screen.sh`) shared by xss-lock (suspend / `loginctl lock-session`) and the `$mod+Escape` binding.

Configured features:

- Dracula theme with customized indicator colors
- Background blur (level 25)
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