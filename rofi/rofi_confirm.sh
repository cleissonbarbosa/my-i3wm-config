#!/usr/bin/env bash
# Themed yes/no confirmation through rofi.
#   rofi_confirm.sh "Sair do i3" && i3-msg exit
# Exits 0 when the user picks "Sim", non-zero otherwise (including Escape).
#
# This exists so nothing in the rice has to fall back to i3-nagbar, which
# draws itself with the default Sans/grey X look and ignores the active theme.
set -uo pipefail

prompt=${1:-Confirmar}

THEME="$HOME/.config/rofi/current-theme.rasi"
theme_args=()
[[ -f "$THEME" ]] && theme_args=(-theme "$THEME")

answer=$(printf 'Não\nSim' | rofi -dmenu -i -p "$prompt?" "${theme_args[@]}" \
  -theme-str 'window { width: 16%; } listview { lines: 2; }') || exit 1

[[ "$answer" == "Sim" ]]
