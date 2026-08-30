#!/usr/bin/env bash
# Random wallpaper slideshow using feh.
# Override via environment: WALLPAPER_DIR, WALLPAPER_INTERVAL (seconds).
#
# Send SIGUSR1 to skip to the next wallpaper immediately ($mod+F5):
#   pkill -USR1 -f '[w]allpaper-slideshow.sh'
# The bracket stops the pattern from matching the shell that runs pkill.

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

# SIGUSR1 only has to interrupt the wait below; the loop then rolls a new
# wallpaper on its own.
trap ':' USR1

while true; do
  # find instead of a glob: it survives sub-directories and non-image files,
  # and the glob would have been passed to feh verbatim on an empty match.
  mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)

  if (( ${#wallpapers[@]} == 0 )); then
    echo "wallpaper-slideshow: no images found in $WALLPAPER_DIR" >&2
    exit 1
  fi

  feh --randomize --bg-fill "${wallpapers[@]}"

  # A backgrounded sleep + `wait` returns as soon as SIGUSR1 arrives;
  # a plain `sleep` would only be interrupted after the trap ran.
  sleep "$WALLPAPER_INTERVAL" &
  wait $! 2>/dev/null
done
