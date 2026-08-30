#!/usr/bin/env bash
# Screenshot straight to the clipboard via Spectacle.
# Usage: screenshot.sh full|monitor|window
#
# Spectacle's own --copy-image is useless outside a KDE session: it hands the
# image to the X11 clipboard and exits immediately, and with no clipboard
# manager holding image selections the data dies with the process (greenclip
# only keeps text). So capture to a temp file and pass it to xclip, which stays
# resident to serve the selection.

set -euo pipefail

case "${1:-}" in
  full)    mode=--fullscreen ;;
  monitor) mode=--current ;;
  window)  mode=--activewindow ;;
  *) echo "usage: $0 full|monitor|window" >&2; exit 1 ;;
esac

notify() { notify-send -a screenshot -u "$1" -t 1500 "󰹑 Captura de tela" "$2"; }

tmp=$(mktemp --suffix=.png -t screenshot-XXXXXX)
trap 'rm -f "$tmp"' EXIT

# --output writes the file instead of copying; --nonotify because we send our
# own once the image is actually in the clipboard.
if ! spectacle "$mode" --background --nonotify --output "$tmp" >/dev/null 2>&1 || [[ ! -s "$tmp" ]]; then
  notify critical "Falha ao capturar"
  exit 1
fi

# xclip reads the file up front and then forks, so removing it here is safe.
xclip -selection clipboard -t image/png -i "$tmp"
notify low "Copiada para a área de transferência"
