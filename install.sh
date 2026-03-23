#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

CONFIG_DIR_DEFAULT="$HOME/.config"
ROFI_ASKPASS_DEFAULT="$HOME/.local/bin/rofi-askpass"
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
WITH_FLAMESHOT=false
BUILD_PICOM=false
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
  --no-deps                Do not install dependencies via apt
  --no-i3                  Do not apply the i3 config
  --no-i3status            Do not apply the i3status-rs config
  --no-picom               Do not apply the picom config
  --no-dunst               Do not apply the dunst config
  --no-wezterm             Do not apply the WezTerm config
  --no-rofi                Do not install rofi scripts
  --no-wallpapers          Do not copy wallpapers from the repo
  --with-gnome-settings    Install gnome-control-center
  --with-flameshot         Install Flameshot via flatpak
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

backup_file() {
  local path="$1"
  if [[ -f "$path" || -L "$path" ]]; then
    mv "$path" "${path}.bak_${TIMESTAMP}"
    log "Backup created: ${path}.bak_${TIMESTAMP}"
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"
  ensure_dir "$(dirname "$dest")"
  backup_file "$dest"
  cp -f "$src" "$dest"
  log "Copied: $src -> $dest"
}

copy_dir() {
  local src="$1"
  local dest="$2"
  ensure_dir "$dest"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    cp -a "$src/." "$dest/"
  fi
  log "Directory synchronized: $src -> $dest"
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
      INSTALL_ROFI=true
      COPY_WALLPAPERS=true
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
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
    --with-flameshot)
      WITH_FLAMESHOT=true
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

    if prompt_yes_no "Install dunst" "y"; then
      install_apt_packages dunst
    fi

    if prompt_yes_no "Install rofi" "y"; then
      install_apt_packages rofi
    fi

    if prompt_yes_no "Install volume and media control tools (pulseaudio-utils playerctl)" "y"; then
      install_apt_packages pulseaudio-utils playerctl
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

    if prompt_yes_no "Install Material Design Icons fonts" "y"; then
      install_apt_packages fonts-material-design-icons-iconfont
    fi

    if prompt_yes_no "Install Flameshot via flatpak" "n"; then
      if command -v flatpak >/dev/null 2>&1; then
        flatpak install -y flathub org.flameshot.Flameshot
      else
        log "flatpak not found. Skipping Flameshot."
      fi
    fi
  else
    install_apt_packages \
      git python3-i3ipc i3 xss-lock dex numlockx feh \
      picom \
      dunst \
      rofi \
      pulseaudio-utils playerctl \
      light \
      network-manager-gnome \
      fonts-material-design-icons-iconfont

    if [[ "$WITH_GNOME_SETTINGS" == "true" ]]; then
      install_apt_packages gnome-control-center
    fi

    if [[ "$WITH_FLAMESHOT" == "true" ]]; then
      if command -v flatpak >/dev/null 2>&1; then
        flatpak install -y flathub org.flameshot.Flameshot
      else
        log "flatpak not found. Skipping Flameshot."
      fi
    fi

    if [[ "$BUILD_PICOM" == "true" ]]; then
      install_apt_packages "${PICOM_DEV_PACKAGES[@]}"
    fi
  fi

  log "Notes:"
  log "- The installer tries to initialize the i3-alternating-layout submodule automatically when needed."
  log "- i3lock-color must be installed manually (fork of i3lock)."
  log "- i3status-rs must be installed manually."
  log "- Brave/Chrome must be installed manually."
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the i3 config" "y"; then
    APPLY_I3=true
  else
    APPLY_I3=false
  fi
fi

if [[ "$APPLY_I3" == "true" ]]; then
  copy_file "$SCRIPT_DIR/i3wm/config" "$CONFIG_DIR/i3/config"

  if ensure_i3_alternating_layout_submodule; then
    copy_dir "$SCRIPT_DIR/i3wm/scripts" "$CONFIG_DIR/i3/scripts"
    chmod +x "$CONFIG_DIR/i3/scripts/i3-alternating-layout/alternating_layouts.py"
    log "i3 scripts updated, including the i3-alternating-layout submodule."
  else
    log "Warning: the i3 config was applied, but the i3-alternating-layout submodule was not available to copy."
  fi
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the i3status-rs config" "y"; then
    APPLY_I3STATUS=true
  else
    APPLY_I3STATUS=false
  fi
fi

if [[ "$APPLY_I3STATUS" == "true" ]]; then
  copy_file "$SCRIPT_DIR/i3wm/i3status/config.toml" "$CONFIG_DIR/i3status/config.toml"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the picom config" "y"; then
    APPLY_PICOM=true
  else
    APPLY_PICOM=false
  fi
fi

if [[ "$APPLY_PICOM" == "true" ]]; then
  copy_file "$SCRIPT_DIR/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf"
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
  copy_file "$SCRIPT_DIR/dunst/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Apply the WezTerm config" "y"; then
    APPLY_WEZTERM=true
  else
    APPLY_WEZTERM=false
  fi
fi

if [[ "$APPLY_WEZTERM" == "true" ]]; then
  copy_file "$SCRIPT_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Install rofi scripts" "y"; then
    INSTALL_ROFI=true
  else
    INSTALL_ROFI=false
  fi
fi

if [[ "$INSTALL_ROFI" == "true" ]]; then
  ROFI_LAUNCHER_DEST="$HOME/rofi_launcher.sh"
  ROFI_SUDO_LAUNCHER_DEST="$HOME/rofi_sudo_launcher.sh"
  ROFI_ASKPASS_DEST="$ROFI_ASKPASS_DEFAULT"

  copy_file "$SCRIPT_DIR/rofi/rofi_launcher.sh" "$ROFI_LAUNCHER_DEST"
  copy_file "$SCRIPT_DIR/rofi/rofi_sudo_launcher.sh" "$ROFI_SUDO_LAUNCHER_DEST"
  copy_file "$SCRIPT_DIR/rofi/rofi-askpass" "$ROFI_ASKPASS_DEST"

  chmod +x "$ROFI_LAUNCHER_DEST" "$ROFI_SUDO_LAUNCHER_DEST" "$ROFI_ASKPASS_DEST"
  log "Execution permissions applied to the rofi scripts."
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

log "Installation complete. Reload i3 with Mod+Shift+r."
