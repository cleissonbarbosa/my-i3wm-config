#!/usr/bin/env bash
# Random wallpaper slideshow using feh.
# Override via environment: WALLPAPER_DIR, WALLPAPER_INTERVAL (seconds).

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/desktop background}"
WALLPAPER_INTERVAL="${WALLPAPER_INTERVAL:-30}"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "wallpaper-slideshow: directory not found: $WALLPAPER_DIR" >&2
  exit 1
fi

# Guard against duplicate instances (e.g. accidental double exec)
pidfile="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-slideshow.pid"
if [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  exit 0
fi
echo $$ > "$pidfile"
trap 'rm -f "$pidfile"' EXIT

while true; do
  feh --randomize --bg-fill "$WALLPAPER_DIR"/*
  sleep "$WALLPAPER_INTERVAL"
done
