#!/usr/bin/env bash
# Rice/theme selector: applies a theme from themes/<name>/ to i3, rofi, dunst,
# wezterm, i3status-rs, eww, the lock screen and GTK, then reloads everything.
#
# Usage:
#   theme-switcher.sh                # pick a theme via rofi menu
#   theme-switcher.sh <name>         # apply a theme directly
#   theme-switcher.sh <name> --no-reload   # apply without reloading (install time)
set -euo pipefail

SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
REPO_DIR=$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)
THEMES_DIR="$REPO_DIR/themes"
STATE_DIR="$HOME/.config/rice-theme"

I3_CONFIG="$REPO_DIR/i3wm/config"
I3STATUS_CONFIG="$REPO_DIR/i3wm/i3status/config.toml"
DUNST_BASE="$REPO_DIR/dunst/dunstrc.base"
DUNST_RULES="$REPO_DIR/dunst/dunstrc.rules"
EWW_COLORS="$REPO_DIR/eww/_colors.scss"

RELOAD=true
THEME=""

for arg in "$@"; do
  case "$arg" in
    --no-reload) RELOAD=false ;;
    *) THEME="$arg" ;;
  esac
done

list_themes() {
  find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

if [[ -z "$THEME" ]]; then
  rofi_theme_args=()
  if [[ -f "$HOME/.config/rofi/current-theme.rasi" ]]; then
    rofi_theme_args=(-theme "$HOME/.config/rofi/current-theme.rasi")
  fi
  THEME=$(list_themes | rofi -dmenu -i -p "󰏘 Theme" "${rofi_theme_args[@]}" \
    -theme-str 'window { width: 16%; } listview { lines: 5; }') || exit 0
  [[ -z "$THEME" ]] && exit 0
fi

THEME_DIR="$THEMES_DIR/$THEME"
if [[ ! -d "$THEME_DIR" ]]; then
  echo "theme-switcher: unknown theme '$THEME' (available: $(list_themes | tr '\n' ' '))" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "$THEME_DIR/colors.sh"

mkdir -p "$STATE_DIR" "$HOME/.config/rofi" "$HOME/.config/dunst"

# Shared color variables (consumed by lock-screen.sh and friends)
ln -sfn "$THEME_DIR/colors.sh" "$STATE_DIR/colors.sh"

# Rofi: every launcher points at current-theme.rasi
ln -sfn "$THEME_DIR/rofi.rasi" "$HOME/.config/rofi/current-theme.rasi"

# WezTerm: .wezterm.lua loads this file and reloads automatically on change
ln -sfn "$THEME_DIR/wezterm.lua" "$STATE_DIR/wezterm-theme.lua"
# Touch through the symlink so wezterm's file watcher notices the change
touch -h "$STATE_DIR/wezterm-theme.lua" 2>/dev/null || true

# eww: copy the palette into the config dir (imported by eww.scss)
if [[ -d "$REPO_DIR/eww" ]]; then
  cp -f "$THEME_DIR/eww.scss" "$EWW_COLORS"
fi

# Splice a theme fragment into the region delimited by the managed markers of
# a config file. Used for both i3 and i3status-rs, which have no include
# directive of their own.
splice_managed_block() {
  local target=$1 fragment=$2 marker=$3 tmp
  tmp=$(mktemp)
  awk -v themefile="$fragment" -v marker="$marker" '
    index($0, "# >>> " marker) == 1 {
      print
      while ((getline line < themefile) > 0) print line
      close(themefile)
      skip = 1
      next
    }
    index($0, "# <<< " marker) == 1 { skip = 0 }
    !skip
  ' "$target" > "$tmp"
  cat "$tmp" > "$target"
  rm -f "$tmp"
}

# i3: splice the theme variables between the managed markers
splice_managed_block "$I3_CONFIG" "$THEME_DIR/i3.conf" "theme colors"

# i3status-rs: bundled theme name, or a full [theme.overrides] palette for the
# themes i3status-rs does not ship (Tokyo Night).
splice_managed_block "$I3STATUS_CONFIG" "$THEME_DIR/i3status.toml" "i3status theme"

# dunst: generated file = base config + theme colors + rules (dunst has no
# include). The rules go last: everything in themes/<name>/dunst.conf before
# its first [urgency_*] header still belongs to the [global] section, so a
# rule section in the base file would swallow it.
rm -f "$HOME/.config/dunst/dunstrc"
cat "$DUNST_BASE" "$THEME_DIR/dunst.conf" "$DUNST_RULES" > "$HOME/.config/dunst/dunstrc"

# --- GTK / icons / cursor ---------------------------------------------------
# GTK apps (Nautilus, gnome-control-center, every file dialog) used to sit
# outside the rice entirely: only the Dracula theme named a GTK theme, and
# nothing ever touched the icon theme, the cursor or the dark-mode preference.
# Each piece below is guarded on being installed, so a rice that names a theme
# this machine does not have leaves that piece alone instead of pointing GTK at
# something that does not exist.

installed_in() {  # installed_in <subdir> <name>
  [[ -d "$HOME/.$1/$2" || -d "/usr/share/$1/$2" ]]
}

set_gtk_key() {  # set_gtk_key <settings.ini> <key> <value>
  local file=$1 key=$2 value=$3
  mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || printf '[Settings]\n' > "$file"
  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

apply_gtk() {  # apply_gtk <settings.ini key> <value> <gsettings key>
  local key=$1 value=$2 gsetting=$3
  gsettings set org.gnome.desktop.interface "$gsetting" "$value" 2>/dev/null || true
  set_gtk_key "$HOME/.config/gtk-3.0/settings.ini" "$key" "$value"
  set_gtk_key "$HOME/.config/gtk-4.0/settings.ini" "$key" "$value"
}

if [[ -n "${GTK_THEME:-}" ]] && installed_in themes "$GTK_THEME"; then
  apply_gtk gtk-theme-name "$GTK_THEME" gtk-theme

  # GTK4 has no theme-name mechanism of its own: apps read
  # ~/.config/gtk-4.0/gtk.css directly. Left unmanaged, that file keeps
  # pointing at whichever rice was applied first and silently overrides every
  # theme switched to afterwards.
  gtk4_src=""
  for base in "$HOME/.themes" "/usr/share/themes"; do
    if [[ -d "$base/$GTK_THEME/gtk-4.0" ]]; then
      gtk4_src="$base/$GTK_THEME/gtk-4.0"
      break
    fi
  done

  mkdir -p "$HOME/.config/gtk-4.0"
  for asset in gtk.css gtk-dark.css assets; do
    target="$HOME/.config/gtk-4.0/$asset"
    if [[ -n "$gtk4_src" && -e "$gtk4_src/$asset" ]]; then
      ln -sfn "$gtk4_src/$asset" "$target"
    elif [[ -L "$target" ]]; then
      # Only ever removes a symlink, which is all this script creates — a real
      # file written by hand is left alone.
      rm -f "$target"
    fi
  done
fi

if [[ -n "${ICON_THEME:-}" ]] && installed_in icons "$ICON_THEME"; then
  apply_gtk gtk-icon-theme-name "$ICON_THEME" icon-theme
fi

if [[ -n "${CURSOR_THEME:-}" ]] && installed_in icons "$CURSOR_THEME"; then
  apply_gtk gtk-cursor-theme-name "$CURSOR_THEME" cursor-theme
fi

# Every bundled rice is dark. Without this, libadwaita and GTK4 apps ignore the
# dark GTK theme and open as a white window in the middle of a dark desktop.
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
set_gtk_key "$HOME/.config/gtk-3.0/settings.ini" gtk-application-prefer-dark-theme 1
set_gtk_key "$HOME/.config/gtk-4.0/settings.ini" gtk-application-prefer-dark-theme 1

# Lock screen: re-render the blurred background cache with the theme wallpaper.
# Passed as an array so an unset LOCK_WALLPAPER sends no argument at all rather
# than an empty one, which the script would have to sift out.
lock_bg_args=()
[[ -n "${LOCK_WALLPAPER:-}" ]] && lock_bg_args=("$LOCK_WALLPAPER")
"$REPO_DIR/i3wm/scripts/update-lock-bg.sh" "${lock_bg_args[@]}" 2>/dev/null || true

echo "$THEME" > "$STATE_DIR/current"

if [[ "$RELOAD" == "true" ]]; then
  i3-msg restart >/dev/null 2>&1 || true
  killall dunst 2>/dev/null || true
  if command -v eww >/dev/null 2>&1; then
    eww reload 2>/dev/null || true
  fi
  sleep 0.5
  notify-send -a theme-switcher "󰏘 Theme" "Applied: $THEME" 2>/dev/null || true
fi

echo "Theme applied: $THEME"
