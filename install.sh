#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

CONFIG_DIR_DEFAULT="$HOME/.config"
LOCAL_BIN_DIR="$HOME/.local/bin"
WALLPAPER_DEFAULT_DIR="$HOME/Pictures/desktop background"
I3_ALTERNATING_LAYOUT_SUBMODULE_PATH="$SCRIPT_DIR/i3wm/scripts/i3-alternating-layout"
I3_ALTERNATING_LAYOUT_SCRIPT="$I3_ALTERNATING_LAYOUT_SUBMODULE_PATH/alternating_layouts.py"

INTERACTIVE=true
INSTALL_DEPS=false
APPLY_I3=true
APPLY_I3STATUS=true
APPLY_PICOM=true
APPLY_DUNST=true
APPLY_WEZTERM=true
INSTALL_ROFI=true
COPY_WALLPAPERS=true
WITH_GNOME_SETTINGS=false
WITH_SPECTACLE=false
BUILD_PICOM=false
# Symlink configs into place so the repository stays the single source of
# truth. Use --copy for standalone copies (the old behavior).
USE_SYMLINK=true
PICOM_SRC_DIR="$HOME/.local/src/picom"

# Development dependencies required to build Picom v13
PICOM_DEV_PACKAGES=(
  meson
  ninja-build
  pkg-config
  git
  libxcb1-dev
  libxcb-util0-dev
  libxcb-ewmh-dev
  libxcb-randr0-dev
  libxcb-composite0-dev
  libxcb-xfixes0-dev
  libxcb-render-util0-dev
  libxcb-shape0-dev
  libx11-dev
  libxrandr-dev
  libxrender-dev
  libxdamage-dev
  libpango1.0-dev
  libglib2.0-dev
  libxkbcommon-dev
  build-essential
)

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --all                    Install dependencies and apply all configs
  --non-interactive        Non-interactive mode (uses defaults or flags)
  --copy                   Copy files instead of symlinking them (default: symlink)
  --no-deps                Do not install dependencies via apt
  --no-i3                  Do not apply the i3 config
  --no-i3status            Do not apply the i3status-rs config
  --no-picom               Do not apply the picom config
  --no-dunst               Do not apply the dunst config
  --no-wezterm             Do not apply the WezTerm config
  --no-rofi                Do not install rofi scripts
  --no-wallpapers          Do not copy wallpapers from the repo
  --with-gnome-settings    Install gnome-control-center
  --with-spectacle         Install Spectacle plus its QML and icon deps via apt
  --config-dir DIR         Set the base config directory (default: ~/.config)
  --wallpaper-dir DIR      Set the wallpaper destination directory
  -h, --help               Show this help message
EOF
}

prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local answer

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "$prompt [Y/n]: " answer || true
      answer=${answer:-y}
    else
      read -r -p "$prompt [y/N]: " answer || true
      answer=${answer:-n}
    fi

    case "$answer" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) log "Type y or n." ;;
    esac
  done
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi
}

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    mv "$path" "${path}.bak_${TIMESTAMP}"
    log "Backup created: ${path}.bak_${TIMESTAMP}"
  fi
}

# Symlink (default) or copy a single file into place, backing up the previous one.
install_file() {
  local src="$1"
  local dest="$2"
  ensure_dir "$(dirname "$dest")"
  if [[ "$USE_SYMLINK" == "true" ]]; then
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      log "Already linked: $dest"
      return 0
    fi
    backup_path "$dest"
    ln -sn "$src" "$dest"
    log "Linked: $dest -> $src"
  else
    backup_path "$dest"
    cp -f "$src" "$dest"
    log "Copied: $src -> $dest"
  fi
}

# Symlink (default) or synchronize a directory into place.
install_dir() {
  local src="$1"
  local dest="$2"
  if [[ "$USE_SYMLINK" == "true" ]]; then
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      log "Already linked: $dest"
      return 0
    fi
    ensure_dir "$(dirname "$dest")"
    backup_path "$dest"
    ln -sn "$src" "$dest"
    log "Linked: $dest -> $src"
  else
    ensure_dir "$dest"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete "$src/" "$dest/"
    else
      cp -a "$src/." "$dest/"
    fi
    log "Directory synchronized: $src -> $dest"
  fi
}

# Always copies (never symlinks): the user adds their own files to this directory.
copy_dir() {
  local src="$1"
  local dest="$2"
  ensure_dir "$dest"
  cp -a "$src/." "$dest/"
  log "Directory copied: $src -> $dest"
}

ensure_i3_alternating_layout_submodule() {
  if [[ -f "$I3_ALTERNATING_LAYOUT_SCRIPT" ]]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    log "git not found. Could not initialize the i3-alternating-layout submodule."
    return 1
  fi

  if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    log "Checkout without git metadata detected. Clone the repository with --recursive to include the i3-alternating-layout submodule."
    return 1
  fi

  log "Initializing i3-alternating-layout submodule..."
  git -C "$SCRIPT_DIR" submodule update --init --recursive -- i3wm/scripts/i3-alternating-layout

  if [[ -f "$I3_ALTERNATING_LAYOUT_SCRIPT" ]]; then
    return 0
  fi

  log "Could not load the i3-alternating-layout submodule."
  return 1
}

install_apt_packages() {
  local -a packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi
  if ! command -v apt >/dev/null 2>&1; then
    log "apt not found. Skipping package installation."
    return 0
  fi
  log "Installing packages: ${packages[*]}"
  sudo apt update
  sudo apt install -y "${packages[@]}"
}

# Clipboard history daemon (static binary, no sudo needed).
install_greenclip() {
  if command -v greenclip >/dev/null 2>&1; then
    log "greenclip is already installed."
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1; then
    log "curl not found. Install greenclip manually: https://github.com/erebe/greenclip/releases"
    return 1
  fi
  log "Downloading greenclip..."
  ensure_dir "$LOCAL_BIN_DIR"
  if curl -fsSL -o "$LOCAL_BIN_DIR/greenclip" \
    "https://github.com/erebe/greenclip/releases/download/v4.2/greenclip"; then
    chmod +x "$LOCAL_BIN_DIR/greenclip"
    log "greenclip installed in $LOCAL_BIN_DIR."
  else
    log "greenclip download failed: https://github.com/erebe/greenclip/releases"
    rm -f "$LOCAL_BIN_DIR/greenclip"
  fi
}

# Python-based rice tools (flash on focus, workspace save/restore, emoji picker).
# An isolated venv avoids PEP 668 conflicts on modern Debian/Ubuntu releases.
install_pip_tools() {
  if ! command -v python3 >/dev/null 2>&1; then
    log "python3 not found. Install flashfocus, i3-resurrect, rofimoji and autotiling manually."
    return 1
  fi

  local venv_dir="$HOME/.local/share/my-i3wm-config/venv"
  log "Installing flashfocus, i3-resurrect, rofimoji and autotiling in $venv_dir..."
  ensure_dir "$(dirname "$venv_dir")"
  python3 -m venv "$venv_dir" || {
    log "Could not create the venv; install python3-venv and try again."
    return 1
  }
  "$venv_dir/bin/python" -m pip install --quiet flashfocus i3-resurrect rofimoji autotiling || {
    log "pip install failed inside $venv_dir."
    return 1
  }

  ensure_dir "$LOCAL_BIN_DIR"
  local command_name
  for command_name in flashfocus i3-resurrect rofimoji autotiling; do
    ln -sfn "$venv_dir/bin/$command_name" "$LOCAL_BIN_DIR/$command_name"
  done
  log "Python rice tools installed and linked in $LOCAL_BIN_DIR."
}

# Download JetBrainsMono Nerd Font to ~/.local/share/fonts (no sudo needed).
# It provides the bar icons (material-nf) and all fonts used by this setup.
install_nerd_font() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    log "JetBrainsMono Nerd Font is already installed."
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    log "curl/unzip not found. Install JetBrainsMono Nerd Font manually: https://www.nerdfonts.com/font-downloads"
    return 1
  fi

  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  local tmp_zip
  tmp_zip=$(mktemp --suffix=.zip)

  log "Downloading JetBrainsMono Nerd Font..."
  if curl -fsSL -o "$tmp_zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
    ensure_dir "$font_dir"
    unzip -o "$tmp_zip" -d "$font_dir" >/dev/null
    fc-cache -f >/dev/null 2>&1 || true
    log "JetBrainsMono Nerd Font installed in $font_dir."
  else
    log "Download failed. Install manually: https://www.nerdfonts.com/font-downloads"
  fi
  rm -f "$tmp_zip"
}

build_picom_from_source() {
  log "Building Picom v13 from source in: $PICOM_SRC_DIR"
  ensure_dir "$(dirname "$PICOM_SRC_DIR")"

  if [[ -d "$PICOM_SRC_DIR/.git" ]]; then
    log "Existing repository found, updating..."
    git -C "$PICOM_SRC_DIR" fetch --tags --all || true
    git -C "$PICOM_SRC_DIR" checkout v13 2>/dev/null || true
    git -C "$PICOM_SRC_DIR" pull --ff-only || true
  else
    log "Cloning picom..."
    if ! git clone git@github.com:yshui/picom.git "$PICOM_SRC_DIR" >/dev/null 2>&1; then
      log "SSH clone failed, trying HTTPS..."
      git clone https://github.com/yshui/picom.git "$PICOM_SRC_DIR"
    fi
    git -C "$PICOM_SRC_DIR" fetch --tags --all || true
    git -C "$PICOM_SRC_DIR" checkout v13 2>/dev/null || true
  fi

  log "Configuring meson..."
  (cd "$PICOM_SRC_DIR" && meson setup --buildtype=release build) || (cd "$PICOM_SRC_DIR" && meson setup build --buildtype=release)
  log "Building with ninja..."
  ninja -C "$PICOM_SRC_DIR/build"
  log "Installing (requires sudo)..."
  sudo ninja -C "$PICOM_SRC_DIR/build" install
  log "Picom built and installed successfully."
}

log "==== i3wm config installer ===="
log "Repository directory: $SCRIPT_DIR"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      INSTALL_DEPS=true
      APPLY_I3=true
      APPLY_I3STATUS=true
      APPLY_PICOM=true
      APPLY_DUNST=true
      APPLY_WEZTERM=true
      INSTALL_ROFI=true
      COPY_WALLPAPERS=true
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --copy)
      USE_SYMLINK=false
      shift
      ;;
    --no-deps)
      INSTALL_DEPS=false
      shift
      ;;
    --no-i3)
      APPLY_I3=false
      shift
      ;;
    --no-i3status)
      APPLY_I3STATUS=false
      shift
      ;;
    --no-picom)
      APPLY_PICOM=false
      shift
      ;;
    --no-dunst)
      APPLY_DUNST=false
      shift
      ;;
    --no-wezterm)
      APPLY_WEZTERM=false
      shift
      ;;
    --no-rofi)
      INSTALL_ROFI=false
      shift
      ;;
    --no-wallpapers)
      COPY_WALLPAPERS=false
      shift
      ;;
    --with-gnome-settings)
      WITH_GNOME_SETTINGS=true
      shift
      ;;
    --with-spectacle)
      WITH_SPECTACLE=true
      shift
      ;;
    --picom-src)
      BUILD_PICOM=true
      shift
      ;;
    --config-dir)
      CONFIG_DIR_DEFAULT="$2"
      shift 2
      ;;
    --wallpaper-dir)
      WALLPAPER_DEFAULT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

CONFIG_DIR="$CONFIG_DIR_DEFAULT"
if [[ "$INTERACTIVE" == "true" ]]; then
  read -r -p "Base config directory [$CONFIG_DIR_DEFAULT]: " CONFIG_DIR_INPUT || true
  if [[ -n "$CONFIG_DIR_INPUT" ]]; then
    CONFIG_DIR="$CONFIG_DIR_INPUT"
  fi
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Install dependencies via apt" "n"; then
    INSTALL_DEPS=true
  fi
fi

if [[ "$INSTALL_DEPS" == "true" ]]; then
  if [[ "$INTERACTIVE" == "true" ]]; then
    if prompt_yes_no "Install i3 and utilities (git python3-i3ipc i3 xss-lock dex numlockx feh)" "y"; then
      install_apt_packages git python3-i3ipc i3 xss-lock dex numlockx feh
    fi

    if prompt_yes_no "Install picom" "y"; then
      install_apt_packages picom
    fi

    if prompt_yes_no "Build Picom v13 from source (requires development dependencies)" "n"; then
      BUILD_PICOM=true
    fi

    # ffmpeg backs the screen-record.sh bindings (x11grab).
    if prompt_yes_no "Install dunst, jq, xclip, ImageMagick and ffmpeg" "y"; then
      install_apt_packages dunst jq xclip imagemagick ffmpeg
    fi

    if prompt_yes_no "Install rofi" "y"; then
      install_apt_packages rofi
    fi

    if prompt_yes_no "Install volume and media control tools (wireplumber playerctl)" "y"; then
      install_apt_packages wireplumber playerctl
    fi

    if prompt_yes_no "Install brightness control (light)" "y"; then
      install_apt_packages light
    fi

    if prompt_yes_no "Install network-manager-gnome" "y"; then
      install_apt_packages network-manager-gnome
    fi

    if prompt_yes_no "Install gnome-control-center (optional)" "n"; then
      install_apt_packages gnome-control-center
    fi

    if prompt_yes_no "Download JetBrainsMono Nerd Font to ~/.local/share/fonts" "y"; then
      install_nerd_font
    fi

    if prompt_yes_no "Install greenclip (clipboard history)" "y"; then
      install_greenclip
    fi

    if prompt_yes_no "Install flashfocus, i3-resurrect, rofimoji and autotiling via pip" "y"; then
      install_apt_packages python3-venv
      install_pip_tools
    fi

    # Neither of the extra packages is pulled in by kde-spectacle, and both are
    # needed outside a KDE session: without qml-module-qtquick-shapes the region
    # selector fails to load its QML overlay and Spectacle exits without
    # capturing anything, and without breeze-icon-theme the annotation toolbar
    # renders blank (KIconThemes defaults to "breeze" and finds nothing).
    if prompt_yes_no "Install Spectacle (screenshots)" "y"; then
      install_apt_packages kde-spectacle qml-module-qtquick-shapes breeze-icon-theme
    fi
  else
    install_apt_packages \
      git python3-i3ipc i3 xss-lock dex numlockx feh \
      picom \
      dunst jq xclip imagemagick ffmpeg \
      rofi \
      wireplumber playerctl \
      light \
      python3-venv \
      network-manager-gnome

    install_nerd_font
    install_greenclip
    install_pip_tools

    if [[ "$WITH_GNOME_SETTINGS" == "true" ]]; then
      install_apt_packages gnome-control-center
    fi

    if [[ "$WITH_SPECTACLE" == "true" ]]; then
      install_apt_packages kde-spectacle qml-module-qtquick-shapes breeze-icon-theme
    fi
  fi

  log "Notes:"
  log "- The installer tries to initialize the i3-alternating-layout submodule automatically when needed."
  log "- i3lock-color must be installed manually (fork of i3lock)."
  log "- i3status-rs must be installed manually."
  log "- Brave/Chrome must be installed manually."
  log "- eww (widgets) must be built manually: sudo apt install libgtk-3-dev libgtk-layer-shell-dev libdbusmenu-gtk3-dev"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the i3 config" "y"; then
    APPLY_I3=true
  else
    APPLY_I3=false
  fi
fi

if [[ "$APPLY_I3" == "true" ]]; then
  install_file "$SCRIPT_DIR/i3wm/config" "$CONFIG_DIR/i3/config"

  # The helper scripts (lock screen, OSDs, dropdown terminal, wallpapers) are
  # installed unconditionally: they must not depend on an optional submodule.
  ensure_i3_alternating_layout_submodule || \
    log "Note: the i3-alternating-layout submodule is unavailable. It is superseded by autotiling anyway."

  install_dir "$SCRIPT_DIR/i3wm/scripts" "$CONFIG_DIR/i3/scripts"
  chmod +x "$CONFIG_DIR/i3/scripts/"*.sh
  if [[ -f "$CONFIG_DIR/i3/scripts/i3-alternating-layout/alternating_layouts.py" ]]; then
    chmod +x "$CONFIG_DIR/i3/scripts/i3-alternating-layout/alternating_layouts.py"
  fi
  log "i3 scripts updated."

  # flashfocus and eww configs (harmless when the tools are not installed)
  install_file "$SCRIPT_DIR/flashfocus/flashfocus.yml" "$CONFIG_DIR/flashfocus/flashfocus.yml"
  install_dir "$SCRIPT_DIR/eww" "$CONFIG_DIR/eww"
  chmod +x "$SCRIPT_DIR/eww/scripts/volume.sh"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the i3status-rs config" "y"; then
    APPLY_I3STATUS=true
  else
    APPLY_I3STATUS=false
  fi
fi

if [[ "$APPLY_I3STATUS" == "true" ]]; then
  install_file "$SCRIPT_DIR/i3wm/i3status/config.toml" "$CONFIG_DIR/i3status/config.toml"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the picom config" "y"; then
    APPLY_PICOM=true
  else
    APPLY_PICOM=false
  fi
fi

if [[ "$APPLY_PICOM" == "true" ]]; then
  install_file "$SCRIPT_DIR/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf"
fi

if [[ "$BUILD_PICOM" == "true" ]]; then
  if [[ "$INSTALL_DEPS" == "true" ]]; then
    install_apt_packages "${PICOM_DEV_PACKAGES[@]}"
  fi
  build_picom_from_source
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the dunst config" "y"; then
    APPLY_DUNST=true
  else
    APPLY_DUNST=false
  fi
fi

if [[ "$APPLY_DUNST" == "true" ]]; then
  # ~/.config/dunst/dunstrc itself is generated by themes/theme-switcher.sh
  # (dunstrc.base + theme colors + dunstrc.rules), which runs at the end of
  # this installer.
  install_file "$SCRIPT_DIR/dunst/dunst-history.sh" "$LOCAL_BIN_DIR/dunst-history.sh"
  install_file "$SCRIPT_DIR/dunst/dunst-dnd.sh" "$LOCAL_BIN_DIR/dunst-dnd.sh"
  chmod +x "$LOCAL_BIN_DIR/dunst-history.sh" "$LOCAL_BIN_DIR/dunst-dnd.sh"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the WezTerm config" "y"; then
    APPLY_WEZTERM=true
  else
    APPLY_WEZTERM=false
  fi
fi

if [[ "$APPLY_WEZTERM" == "true" ]]; then
  install_file "$SCRIPT_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Install rofi scripts" "y"; then
    INSTALL_ROFI=true
  else
    INSTALL_ROFI=false
  fi
fi

if [[ "$INSTALL_ROFI" == "true" ]]; then
  # The rofi color theme (~/.config/rofi/current-theme.rasi) is managed by
  # themes/theme-switcher.sh, which runs at the end of this installer.
  install_file "$SCRIPT_DIR/rofi/rofi_launcher.sh" "$LOCAL_BIN_DIR/rofi_launcher.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_sudo_launcher.sh" "$LOCAL_BIN_DIR/rofi_sudo_launcher.sh"
  install_file "$SCRIPT_DIR/rofi/rofi-askpass" "$LOCAL_BIN_DIR/rofi-askpass"
  install_file "$SCRIPT_DIR/rofi/rofi_powermenu.sh" "$LOCAL_BIN_DIR/rofi_powermenu.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_confirm.sh" "$LOCAL_BIN_DIR/rofi_confirm.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_calc.sh" "$LOCAL_BIN_DIR/rofi_calc.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_clipboard.sh" "$LOCAL_BIN_DIR/rofi_clipboard.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_wifi.sh" "$LOCAL_BIN_DIR/rofi_wifi.sh"
  install_file "$SCRIPT_DIR/rofi/rofi_keybinds.sh" "$LOCAL_BIN_DIR/rofi_keybinds.sh"
  install_file "$SCRIPT_DIR/themes/theme-switcher.sh" "$LOCAL_BIN_DIR/theme-switcher.sh"

  chmod +x "$LOCAL_BIN_DIR/rofi_launcher.sh" "$LOCAL_BIN_DIR/rofi_sudo_launcher.sh" \
           "$LOCAL_BIN_DIR/rofi-askpass" "$LOCAL_BIN_DIR/rofi_powermenu.sh" \
           "$LOCAL_BIN_DIR/rofi_confirm.sh" \
           "$LOCAL_BIN_DIR/rofi_calc.sh" "$LOCAL_BIN_DIR/rofi_clipboard.sh" \
           "$LOCAL_BIN_DIR/rofi_wifi.sh" "$LOCAL_BIN_DIR/rofi_keybinds.sh" \
           "$LOCAL_BIN_DIR/theme-switcher.sh"
  log "Execution permissions applied to the rofi scripts."

  # Older versions of this installer put the launchers directly in $HOME.
  for legacy in "$HOME/rofi_launcher.sh" "$HOME/rofi_sudo_launcher.sh"; do
    if [[ -e "$legacy" || -L "$legacy" ]]; then
      backup_path "$legacy"
      log "Legacy launcher moved out of \$HOME: $legacy"
    fi
  done
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Copy wallpapers from the repo" "y"; then
    COPY_WALLPAPERS=true
  else
    COPY_WALLPAPERS=false
  fi
fi

if [[ "$COPY_WALLPAPERS" == "true" ]]; then
  if [[ -d "$SCRIPT_DIR/desktop-wallpapers" ]]; then
    if [[ "$INTERACTIVE" == "true" ]]; then
      read -r -p "Wallpaper destination [$WALLPAPER_DEFAULT_DIR]: " WALLPAPER_DIR_INPUT || true
      if [[ -n "$WALLPAPER_DIR_INPUT" ]]; then
        WALLPAPER_DEFAULT_DIR="$WALLPAPER_DIR_INPUT"
      fi
    fi
    copy_dir "$SCRIPT_DIR/desktop-wallpapers" "$WALLPAPER_DEFAULT_DIR"
  else
    log "desktop-wallpapers directory not found."
  fi
fi

# Apply the rice theme (colors for i3, rofi, dunst, wezterm, i3status, lock screen)
CURRENT_THEME=$(cat "$HOME/.config/rice-theme/current" 2>/dev/null || echo "dracula")
log "Applying rice theme: $CURRENT_THEME"
"$SCRIPT_DIR/themes/theme-switcher.sh" "$CURRENT_THEME" --no-reload || \
  log "Warning: theme could not be applied; run themes/theme-switcher.sh manually."

log "Installation complete. Reload i3 with Mod+Shift+r."
