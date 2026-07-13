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

# i3: splice the theme variables between the managed markers
tmp=$(mktemp)
awk -v themefile="$THEME_DIR/i3.conf" '
  /^# >>> theme colors/ {
    print
    while ((getline line < themefile) > 0) print line
    close(themefile)
    skip = 1
    next
  }
  /^# <<< theme colors/ { skip = 0 }
  !skip
' "$I3_CONFIG" > "$tmp"
cat "$tmp" > "$I3_CONFIG"
rm -f "$tmp"

# i3status-rs: swap the bundled theme name
sed -i "s/^theme = \".*\"/theme = \"$I3STATUS_THEME\"/" "$I3STATUS_CONFIG"

# dunst: generated file = base config + theme colors (dunst has no include)
rm -f "$HOME/.config/dunst/dunstrc"
cat "$DUNST_BASE" "$THEME_DIR/dunst.conf" > "$HOME/.config/dunst/dunstrc"

# GTK: only switch when the theme ships a GTK theme that is installed
if [[ -n "${GTK_THEME:-}" ]] && { [[ -d "$HOME/.themes/$GTK_THEME" ]] || [[ -d "/usr/share/themes/$GTK_THEME" ]]; }; then
  gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
  if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]]; then
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$HOME/.config/gtk-3.0/settings.ini"
  fi
fi

# Lock screen: re-render the blurred background cache with the theme wallpaper
"$REPO_DIR/i3wm/scripts/update-lock-bg.sh" "${LOCK_WALLPAPER:-}" 2>/dev/null || true

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
