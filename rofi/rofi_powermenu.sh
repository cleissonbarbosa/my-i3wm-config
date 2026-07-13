#!/usr/bin/env bash
# Rofi power menu: lock, suspend, logout, reboot, shutdown (with confirmation).

THEME="$HOME/.config/rofi/current-theme.rasi"
SIZE='window { width: 16%; } listview { lines: 5; }'

confirm() {
  local answer
  answer=$(printf 'Não\nSim' | rofi -dmenu -i -p "$1?" -theme "$THEME" \
    -theme-str 'window { width: 16%; } listview { lines: 2; }')
  [[ "$answer" == "Sim" ]]
}

chosen=$(printf '󰌾 Bloquear\n󰤄 Suspender\n󰍃 Sair do i3\n󰜉 Reiniciar\n󰐥 Desligar' \
  | rofi -dmenu -i -p "⏻ " -theme "$THEME" -theme-str "$SIZE") || exit 0

case "$chosen" in
  *Bloquear)  loginctl lock-session ;;
  *Suspender) systemctl suspend ;;
  *"Sair do i3") confirm "Sair da sessão" && i3-msg exit ;;
  *Reiniciar) confirm "Reiniciar" && systemctl reboot ;;
  *Desligar)  confirm "Desligar" && systemctl poweroff ;;
esac
