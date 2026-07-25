#!/usr/bin/env bash
# Wi-Fi picker built on nmcli + rofi.
#   - lists the visible networks with signal strength and security
#   - reuses a saved connection when there is one, otherwise asks for the
#     password through rofi (hidden input)
#   - the first entries toggle the radio and open nm-connection-editor
set -uo pipefail

THEME="$HOME/.config/rofi/current-theme.rasi"
theme_args=()
[[ -f "$THEME" ]] && theme_args=(-theme "$THEME")

if ! command -v nmcli >/dev/null 2>&1; then
  notify-send -u critical "Wi-Fi" "nmcli não encontrado (instale network-manager)"
  exit 1
fi

notify() { notify-send -a wifi -t 4000 "󰤨 Wi-Fi" "$1"; }

menu() {
  rofi -dmenu -i -p "󰤨 Wi-Fi" "${theme_args[@]}" \
    -theme-str 'window { width: 30%; } listview { lines: 10; }'
}

radio=$(nmcli -t radio wifi)
if [[ "$radio" != "enabled" ]]; then
  choice=$(printf '󰖩 Ligar o Wi-Fi\n󰤮 Cancelar' | menu)
  [[ "$choice" == *Ligar* ]] || exit 0
  nmcli radio wifi on
  notify "Rádio ligado, procurando redes..."
  sleep 2
fi

# Rescan in the background; nmcli list falls back to the cached results.
nmcli device wifi rescan >/dev/null 2>&1 &

active=$(nmcli -t -f ACTIVE,SSID device wifi list 2>/dev/null | awk -F: '$1=="sim"||$1=="yes"{print $2; exit}')

# SSID:SECURITY:SIGNAL -> "  SSID   72%  WPA2"
networks=$(nmcli --get-values SSID,SECURITY,SIGNAL device wifi list 2>/dev/null \
  | awk -F: '
      $1 == "" { next }
      seen[$1]++ { next }
      {
        sig = $3 + 0
        icon = sig >= 75 ? "󰤨" : sig >= 50 ? "󰤥" : sig >= 25 ? "󰤢" : "󰤟"
        lock = ($2 == "" || $2 == "--") ? "󰦞 aberta" : "󰌾 " $2
        printf "%s  %s   %d%%  %s\n", icon, $1, sig, lock
      }')

header="󰑓 Atualizar\n󰖪 Desligar o Wi-Fi\n󰒓 Gerenciar conexões"
[[ -n "$active" ]] && header="󰅖 Desconectar de $active\n$header"

chosen=$(printf '%b\n%s' "$header" "$networks" | menu) || exit 0
[[ -z "$chosen" ]] && exit 0

case "$chosen" in
  󰅖*)
    nmcli connection down id "$active" >/dev/null && notify "Desconectado de $active"
    exit 0 ;;
  󰑓*)
    exec "$0" ;;
  󰖪*)
    nmcli radio wifi off && notify "Rádio desligado"
    exit 0 ;;
  󰒓*)
    exec nm-connection-editor ;;
esac

# Strip the icon prefix and everything from the signal column onwards.
ssid=$(sed -E 's/^[^ ]+  //; s/   [0-9]+%  .*$//' <<<"$chosen")
[[ -z "$ssid" ]] && exit 0

notify "Conectando a $ssid..."

# A saved profile already carries the password.
if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
  if nmcli connection up id "$ssid" >/dev/null 2>&1; then
    notify "Conectado a $ssid"
    exit 0
  fi
fi

connect_args=()
if [[ "$chosen" != *"aberta"* ]]; then
  password=$(rofi -dmenu -password -p "󰌾 Senha de $ssid" "${theme_args[@]}" \
    -theme-str 'window { width: 26%; } listview { lines: 0; }') || exit 0
  [[ -n "$password" ]] && connect_args=(password "$password")
fi

if out=$(nmcli device wifi connect "$ssid" "${connect_args[@]}" 2>&1); then
  notify "Conectado a $ssid"
else
  notify-send -u critical -a wifi "󰤭 Wi-Fi" "Falha ao conectar a $ssid\n$out"
fi
