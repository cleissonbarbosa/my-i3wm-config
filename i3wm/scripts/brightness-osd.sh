#!/usr/bin/env bash
# Brightness control with a dunst OSD progress bar.
# Usage: brightness-osd.sh up|down|get|set <percent>
#
# Three backends, detected automatically:
#   1. light   — real backlight (laptop panels, /sys/class/backlight)
#   2. ddcutil — DDC/CI, i.e. the monitor's own backlight over the video
#                cable. The best option on a desktop, but it needs the
#                i2c-dev module loaded and the user in the "i2c" group.
#   3. xrandr  — software gamma. Always available and needs no permissions,
#                but it only dims the image, it does not touch the panel.
#
# The fallback chain exists because `light` reports 0 and does nothing at all
# on a desktop with no backlight controller, which silently broke the
# brightness keys and the eww slider.
set -uo pipefail

STEP=5
MIN=10   # never let a backendless dim go all the way to a black screen
STATE="${XDG_RUNTIME_DIR:-/tmp}/brightness-level"

detect_backend() {
  if command -v light >/dev/null 2>&1 && compgen -G "/sys/class/backlight/*" >/dev/null; then
    echo backlight
  elif command -v ddcutil >/dev/null 2>&1 && ddcutil detect --brief >/dev/null 2>&1; then
    echo ddcutil
  else
    echo xrandr
  fi
}

BACKEND="${BRIGHTNESS_BACKEND:-$(detect_backend)}"

clamp() {
  local v=$1
  (( v < MIN )) && v=$MIN
  (( v > 100 )) && v=100
  echo "$v"
}

get_level() {
  case "$BACKEND" in
    backlight) LC_ALL=C light -G 2>/dev/null | tr ',' '.' | cut -d. -f1 ;;
    ddcutil)   ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}' ;;
    xrandr)
      # xrandr cannot be queried for its brightness factor, so the last value
      # written is kept on disk.
      if [[ -r "$STATE" ]]; then cat "$STATE"; else echo 100; fi
      ;;
  esac
}

set_level() {
  local level output factor
  level=$(clamp "$1")

  case "$BACKEND" in
    backlight)
      light -S "$level"
      ;;
    ddcutil)
      ddcutil setvcp 10 "$level" >/dev/null 2>&1
      ;;
    xrandr)
      factor=$(LC_ALL=C awk -v l="$level" 'BEGIN{printf "%.2f", l/100}')
      # Apply to every connected output so both monitors stay in sync.
      while read -r output; do
        xrandr --output "$output" --brightness "$factor"
      done < <(xrandr --listmonitors | awk 'NR>1 {print $NF}')
      echo "$level" > "$STATE"
      ;;
  esac

  echo "$level"
}

current=$(get_level)
[[ "$current" =~ ^[0-9]+$ ]] || current=100

case "${1:-}" in
  up)   value=$(set_level $((current + STEP))) ;;
  down) value=$(set_level $((current - STEP))) ;;
  set)  value=$(set_level "${2:?usage: $0 set <percent>}") ;;
  get)  echo "$current"; exit 0 ;;
  *) echo "usage: $0 up|down|get|set <percent>" >&2; exit 1 ;;
esac

notify-send -a brightness-osd -u low -t 1500 \
  -h string:x-dunst-stack-tag:osd \
  -h int:value:"$value" \
  "󰃟 Brilho: ${value}%"
