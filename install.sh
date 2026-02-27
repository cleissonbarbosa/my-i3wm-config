#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

CONFIG_DIR_DEFAULT="$HOME/.config"
ROFI_ASKPASS_DEFAULT="$HOME/.local/bin/rofi-askpass"
WALLPAPER_DEFAULT_DIR="$HOME/Pictures/desktop background"

INTERACTIVE=true
INSTALL_DEPS=false
APPLY_I3=true
APPLY_I3STATUS=true
APPLY_PICOM=true
APPLY_DUNST=true
INSTALL_ROFI=true
COPY_WALLPAPERS=true
WITH_GNOME_SETTINGS=false
WITH_FLAMESHOT=false
BUILD_PICOM=false
PICOM_SRC_DIR="$HOME/.local/src/picom"

# Dependencias de desenvolvimento necessárias para compilar o Picom v13
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
Uso: ./install.sh [opcoes]

Opcoes:
  --all                    Instala dependencias e aplica todas as configs
  --non-interactive         Modo nao-interativo (usa defaults ou flags)
  --no-deps                 Nao instala dependencias via apt
  --no-i3                   Nao aplica config do i3
  --no-i3status             Nao aplica config do i3status-rs
  --no-picom                Nao aplica config do picom
  --no-dunst                Nao aplica config do dunst
  --no-rofi                 Nao instala scripts do rofi
  --no-wallpapers           Nao copia wallpapers do repo
  --with-gnome-settings     Instala gnome-control-center
  --with-flameshot          Instala Flameshot via flatpak
  --config-dir DIR          Define o diretorio base de config (default: ~/.config)
  --wallpaper-dir DIR       Define o destino dos wallpapers
  -h, --help                Mostra esta ajuda
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
      *) log "Digite y ou n." ;;
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
    log "Backup criado: ${path}.bak_${TIMESTAMP}"
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"
  ensure_dir "$(dirname "$dest")"
  backup_file "$dest"
  cp -f "$src" "$dest"
  log "Copiado: $src -> $dest"
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
  log "Diretorio sincronizado: $src -> $dest"
}

install_apt_packages() {
  local -a packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi
  if ! command -v apt >/dev/null 2>&1; then
    log "apt nao encontrado. Pulei instalacao de pacotes."
    return 0
  fi
  log "Instalando pacotes: ${packages[*]}"
  sudo apt update
  sudo apt install -y "${packages[@]}"
}

build_picom_from_source() {
  log "Compilando Picom v13 a partir do fonte em: $PICOM_SRC_DIR"
  ensure_dir "$(dirname "$PICOM_SRC_DIR")"

  if [[ -d "$PICOM_SRC_DIR/.git" ]]; then
    log "Repositorio existente encontrado, atualizando..."
    git -C "$PICOM_SRC_DIR" fetch --tags --all || true
    git -C "$PICOM_SRC_DIR" checkout v13 2>/dev/null || true
    git -C "$PICOM_SRC_DIR" pull --ff-only || true
  else
    log "Clonando picom..."
    if ! git clone git@github.com:yshui/picom.git "$PICOM_SRC_DIR" >/dev/null 2>&1; then
      log "Clone via SSH falhou, tentando HTTPS..."
      git clone https://github.com/yshui/picom.git "$PICOM_SRC_DIR"
    fi
    git -C "$PICOM_SRC_DIR" fetch --tags --all || true
    git -C "$PICOM_SRC_DIR" checkout v13 2>/dev/null || true
  fi

  log "Configurando meson..."
  (cd "$PICOM_SRC_DIR" && meson setup --buildtype=release build) || (cd "$PICOM_SRC_DIR" && meson setup build --buildtype=release)
  log "Compilando com ninja..."
  ninja -C "$PICOM_SRC_DIR/build"
  log "Instalando (requer sudo)..."
  sudo ninja -C "$PICOM_SRC_DIR/build" install
  log "Picom compilado e instalado com sucesso."
}

log "==== Instalador i3wm config ===="
log "Diretorio do repo: $SCRIPT_DIR"

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
      log "Opcao desconhecida: $1"
      usage
      exit 1
      ;;
  esac
done

CONFIG_DIR="$CONFIG_DIR_DEFAULT"
if [[ "$INTERACTIVE" == "true" ]]; then
  read -r -p "Diretorio base de config [$CONFIG_DIR_DEFAULT]: " CONFIG_DIR_INPUT || true
  if [[ -n "$CONFIG_DIR_INPUT" ]]; then
    CONFIG_DIR="$CONFIG_DIR_INPUT"
  fi
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Instalar dependencias via apt" "n"; then
    INSTALL_DEPS=true
  fi
fi

if [[ "$INSTALL_DEPS" == "true" ]]; then
  if [[ "$INTERACTIVE" == "true" ]]; then
    if prompt_yes_no "Instalar i3 e utilitarios (i3 xss-lock dex numlockx feh)" "y"; then
      install_apt_packages i3 xss-lock dex numlockx feh
    fi

    if prompt_yes_no "Instalar picom" "y"; then
      install_apt_packages picom
    fi

    if prompt_yes_no "Compilar Picom v13 a partir do fonte (requer dependencias de desenvolvimento)" "n"; then
      BUILD_PICOM=true
    fi

    if prompt_yes_no "Instalar dunst" "y"; then
      install_apt_packages dunst
    fi

    if prompt_yes_no "Instalar rofi" "y"; then
      install_apt_packages rofi
    fi

    if prompt_yes_no "Instalar controle de volume e midia (pulseaudio-utils playerctl)" "y"; then
      install_apt_packages pulseaudio-utils playerctl
    fi

    if prompt_yes_no "Instalar controle de brilho (light)" "y"; then
      install_apt_packages light
    fi

    if prompt_yes_no "Instalar network-manager-gnome" "y"; then
      install_apt_packages network-manager-gnome
    fi

    if prompt_yes_no "Instalar gnome-control-center (opcional)" "n"; then
      install_apt_packages gnome-control-center
    fi

    if prompt_yes_no "Instalar fontes Material Design Icons" "y"; then
      install_apt_packages fonts-material-design-icons-iconfont
    fi

    if prompt_yes_no "Instalar Flameshot via flatpak" "n"; then
      if command -v flatpak >/dev/null 2>&1; then
        flatpak install -y flathub org.flameshot.Flameshot
      else
        log "flatpak nao encontrado. Pulei Flameshot."
      fi
    fi
  else
    install_apt_packages \
      i3 xss-lock dex numlockx feh \
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
        log "flatpak nao encontrado. Pulei Flameshot."
      fi
    fi

    if [[ "$BUILD_PICOM" == "true" ]]; then
      install_apt_packages "${PICOM_DEV_PACKAGES[@]}"
    fi
  fi

  log "Notas:"
  log "- i3lock-color precisa ser instalado manualmente (fork do i3lock)."
  log "- i3status-rs precisa ser instalado manualmente."
  log "- Brave/Chrome sao instalacao manual."
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Aplicar config do i3" "y"; then
    APPLY_I3=true
  else
    APPLY_I3=false
  fi
fi

if [[ "$APPLY_I3" == "true" ]]; then
  copy_file "$SCRIPT_DIR/i3wm/config" "$CONFIG_DIR/i3/config"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Aplicar config do i3status-rs" "y"; then
    APPLY_I3STATUS=true
  else
    APPLY_I3STATUS=false
  fi
fi

if [[ "$APPLY_I3STATUS" == "true" ]]; then
  copy_file "$SCRIPT_DIR/i3wm/i3status/config.toml" "$CONFIG_DIR/i3status/config.toml"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Aplicar config do picom" "y"; then
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
  if prompt_yes_no "Aplicar config do dunst" "y"; then
    APPLY_DUNST=true
  else
    APPLY_DUNST=false
  fi
fi

if [[ "$APPLY_DUNST" == "true" ]]; then
  copy_file "$SCRIPT_DIR/dunst/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Instalar scripts do rofi" "y"; then
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
  log "Permissoes de execucao aplicadas nos scripts do rofi."
fi

if [[ "$INTERACTIVE" == "true" ]]; then
  if prompt_yes_no "Copiar wallpapers do repo" "y"; then
    COPY_WALLPAPERS=true
  else
    COPY_WALLPAPERS=false
  fi
fi

if [[ "$COPY_WALLPAPERS" == "true" ]]; then
  if [[ -d "$SCRIPT_DIR/desktop-wallpapers" ]]; then
    if [[ "$INTERACTIVE" == "true" ]]; then
      read -r -p "Destino dos wallpapers [$WALLPAPER_DEFAULT_DIR]: " WALLPAPER_DIR_INPUT || true
      if [[ -n "$WALLPAPER_DIR_INPUT" ]]; then
        WALLPAPER_DEFAULT_DIR="$WALLPAPER_DIR_INPUT"
      fi
    fi
    copy_dir "$SCRIPT_DIR/desktop-wallpapers" "$WALLPAPER_DEFAULT_DIR"
  else
    log "Diretorio desktop-wallpapers nao encontrado."
  fi
fi

log "Instalacao concluida. Recarregue o i3 com Mod+Shift+r."
