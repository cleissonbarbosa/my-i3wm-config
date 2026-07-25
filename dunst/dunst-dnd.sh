#!/usr/bin/env bash
# Toggle dunst's do-not-disturb mode ($mod+Shift+comma).
# The i3status-rs `notify` block shows the same state in the bar; this just
# gives it a keyboard shortcut and a confirmation toast.
set -uo pipefail

if ! command -v dunstctl >/dev/null 2>&1; then
  notify-send -u critical "Dunst" "dunstctl não encontrado"
  exit 1
fi

osd() {
  notify-send -a dnd -u low -t 1500 -h string:x-dunst-stack-tag:osd "$1"
}

if [[ "$(dunstctl is-paused)" == "true" ]]; then
  dunstctl set-paused false
  osd "󰂚 Notificações ligadas"
else
  # Announce it while the daemon is still showing notifications, otherwise the
  # toast would sit in the queue until DND is turned off again.
  osd "󰂛 Não perturbe"
  sleep 0.6
  dunstctl set-paused true
fi
