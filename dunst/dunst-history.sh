#!/usr/bin/env bash
# Browse the dunst notification history with rofi and re-show ("pop") the chosen one.
# Requires jq.

if ! command -v jq >/dev/null; then
  notify-send "dunst-history" "This script requires the 'jq' package." 2>/dev/null
  echo "Error: this script requires the 'jq' package." >&2
  exit 1
fi

notifications=$(dunstctl history | jq -r '.data[0] | reverse | .[] | "\(.id.data): \(.summary.data)"')

chosen=$(echo "$notifications" | rofi -dmenu -i -p "Notifications" -theme "$HOME/.config/rofi/current-theme.rasi")

if [[ -n "$chosen" ]]; then
  id=$(echo "$chosen" | cut -d':' -f1)
  dunstctl history-pop "$id"
fi
