#!/usr/bin/env bash
# Dracula-themed lock screen. Requires i3lock-color (https://github.com/Raymo111/i3lock-color);
# the stock i3lock does not support these options.
# Invoked by xss-lock (suspend / "loginctl lock-session") and the $mod+Escape binding.

alpha='dd'
selection='#44475a'
red='#ff5555'
orange='#ffb86c'
magenta='#ff79c6'
blue='#6272a4'
green='#50fa7b'

font='JetBrainsMono Nerd Font'

exec i3lock \
  --insidever-color="${selection}${alpha}" \
  --insidewrong-color="${selection}${alpha}" \
  --inside-color="${selection}${alpha}" \
  --ringver-color="${green}${alpha}" \
  --ringwrong-color="${red}${alpha}" \
  --ring-color="${blue}${alpha}" \
  --line-uses-ring \
  --keyhl-color="${magenta}${alpha}" \
  --bshl-color="${orange}${alpha}" \
  --separator-color="${selection}${alpha}" \
  --verif-color="${green}" \
  --wrong-color="${red}" \
  --modif-color="${red}" \
  --layout-color="${blue}" \
  --date-color="${blue}" \
  --time-color="${blue}" \
  --screen 1 \
  --blur 25 \
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
