#!/usr/bin/env bash
# Pre-renders the blurred lock-screen background so locking is instant
# (i3lock's --blur renders on every lock; this caches the result once).
# Usage: update-lock-bg.sh [image ...]   (default: the current feh wallpapers)
#
# The cache is built at the size of the whole X screen, with each monitor's
# region filled independently. A single 1920x1080 image handed to i3lock's
# --fill on a 3840x1080 screen gets scaled 2x to cover it, so the wallpaper
# ended up blown up and cropped on top of the blur.
set -uo pipefail

cache_dir="$HOME/.cache/i3lock"
out="$cache_dir/bg.png"

# --- source images ----------------------------------------------------------
# feh records one path per monitor in ~/.fehbg, so keep all of them: monitor N
# gets image N, wrapping around when there are fewer images than monitors.
# Only readable files count: theme-switcher.sh calls this with an empty
# LOCK_WALLPAPER when the rice pins no wallpaper of its own, and the .fehbg
# line quotes feh's flags alongside the paths.
images=()
for img in "$@"; do
  [[ -n "$img" && -f "$img" ]] && images+=("$img")
done

if (( ${#images[@]} == 0 )); then
  while IFS= read -r img; do
    [[ -f "$img" ]] && images+=("$img")
  done < <(grep -oP "(?<=')[^']+(?=')" "$HOME/.fehbg" 2>/dev/null)
fi

if (( ${#images[@]} == 0 )); then
  echo "update-lock-bg: no wallpaper found (pass an image path)" >&2
  exit 1
fi

# --- monitor geometry -------------------------------------------------------
# "WIDTHxHEIGHT+X+Y" per output, from xrandr's own numbers rather than an
# assumed resolution. The /NNN physical-size parts are stripped.
mapfile -t monitors < <(
  xrandr --listmonitors 2>/dev/null | awk 'NR>1 {print $3}' | sed 's#/[0-9]*##g'
)

screen=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2; exit}')

if (( ${#monitors[@]} == 0 )) || [[ -z "$screen" ]]; then
  # No X connection (or xrandr missing): fall back to a single-screen render.
  screen=${screen:-1920x1080}
  monitors=("$screen+0+0")
fi

mkdir -p "$cache_dir"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

convert -size "$screen" xc:black "$tmpdir/canvas.png"

i=0
for geom in "${monitors[@]}"; do
  size=${geom%%+*}                  # 1920x1080
  offset=+${geom#*+}                # +0+0  /  +1920+0
  img=${images[i % ${#images[@]}]}

  convert "$img" -resize "${size}^" -gravity center -extent "$size" \
    -blur 0x10 "$tmpdir/monitor-$i.png"
  composite -geometry "$offset" "$tmpdir/monitor-$i.png" \
    "$tmpdir/canvas.png" "$tmpdir/canvas.png"

  i=$((i + 1))
done

mv "$tmpdir/canvas.png" "$out"
echo "Lock background cached: $out (${screen}, ${#monitors[@]} monitor(s))"
