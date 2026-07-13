#!/usr/bin/env bash
# Themed lock screen. Requires i3lock-color (https://github.com/Raymo111/i3lock-color);
# the stock i3lock does not support these options.
# Invoked by xss-lock (suspend / "loginctl lock-session") and the $mod+Escape binding.
#
# Colors come from the active rice theme; the background is a pre-blurred cache
# (see update-lock-bg.sh) so locking is instant, with --blur as fallback.

# Theme palette (falls back to Dracula when no theme has been applied yet)
if [[ -f "$HOME/.config/rice-theme/colors.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/rice-theme/colors.sh"
fi
: "${SELECTION:=#44475a}"
: "${COMMENT:=#6272a4}"
: "${RED:=#ff5555}"
: "${ORANGE:=#ffb86c}"
: "${MAGENTA:=#ff79c6}"
: "${BLUE:=#6272a4}"
: "${GREEN:=#50fa7b}"

alpha='dd'
font='JetBrainsMono Nerd Font'

# Pre-rendered background cache; fall back to live blur (slower)
bg_args=(--blur 25)
if [[ -f "$HOME/.cache/i3lock/bg.png" ]]; then
  bg_args=(--image "$HOME/.cache/i3lock/bg.png" --fill)
fi

exec i3lock \
  "${bg_args[@]}" \
  --insidever-color="${SELECTION}${alpha}" \
  --insidewrong-color="${SELECTION}${alpha}" \
  --inside-color="${SELECTION}${alpha}" \
  --ringver-color="${GREEN}${alpha}" \
  --ringwrong-color="${RED}${alpha}" \
  --ring-color="${BLUE}${alpha}" \
  --line-uses-ring \
  --keyhl-color="${MAGENTA}${alpha}" \
  --bshl-color="${ORANGE}${alpha}" \
  --separator-color="${SELECTION}${alpha}" \
  --verif-color="${GREEN}" \
  --wrong-color="${RED}" \
  --modif-color="${RED}" \
  --layout-color="${BLUE}" \
  --date-color="${BLUE}" \
  --time-color="${BLUE}" \
  --screen 1 \
  --clock \
  --indicator \
  --time-str="%H:%M:%S" \
  --date-str="%A %e %B %Y" \
  --verif-text="Checking..." \
  --wrong-text="Wrong pswd" \
  --noinput="No Input" \
  --lock-text="Locking..." \
  --lockfailed="Lock Failed" \
  --radius=120 \
  --ring-width=10 \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --time-font="${font}" \
  --date-font="${font}" \
  --layout-font="${font}" \
  --verif-font="${font}" \
  --wrong-font="${font}" \
  --nofork
