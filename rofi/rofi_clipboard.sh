#!/usr/bin/env bash
# Clipboard history via greenclip + rofi. Selecting an entry copies it back
# to the clipboard.

if ! command -v greenclip >/dev/null 2>&1; then
  notify-send -u critical "Clipboard" "greenclip não está instalado (rode ./install.sh)"
  exit 1
fi

rofi -modes "clipboard:greenclip print" -show clipboard -run-command '{cmd}' \
  -theme "$HOME/.config/rofi/current-theme.rasi" \
  -display-clipboard "󰅍 : "
