#!/usr/bin/env bash
# Pre-renders the blurred lock-screen background so locking is instant
# (i3lock's --blur renders on every lock; this caches the result once).
# Usage: update-lock-bg.sh [image]  (default: current feh wallpaper)

img="${1:-}"
if [[ -z "$img" ]]; then
  img=$(grep -oP "(?<=')[^']+(?=')" "$HOME/.fehbg" 2>/dev/null | head -1)
fi
if [[ ! -f "$img" ]]; then
  echo "update-lock-bg: no wallpaper found (pass an image path)" >&2
  exit 1
fi

cache_dir="$HOME/.cache/i3lock"
mkdir -p "$cache_dir"

convert "$img" -resize 1920x1080^ -gravity center -extent 1920x1080 \
  -blur 0x10 "$cache_dir/bg.png"
echo "Lock background cached: $cache_dir/bg.png (from $img)"
