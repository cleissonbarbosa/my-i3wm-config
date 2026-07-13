#!/usr/bin/env bash
# Brightness control with a dunst OSD progress bar.
# Usage: brightness-osd.sh up|down

case "${1:-}" in
  up)   light -A 5 ;;
  down) light -U 5 ;;
  *) echo "usage: $0 up|down" >&2; exit 1 ;;
esac

val=$(LC_ALL=C light -G | tr ',' '.' | cut -d. -f1)

notify-send -a brightness-osd -u low -t 1500 \
  -h string:x-dunst-stack-tag:osd \
  -h int:value:"$val" \
  "󰃟 Brilho: ${val}%"
