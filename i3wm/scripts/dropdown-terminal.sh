#!/usr/bin/env bash
# Quake-style dropdown terminal on the i3 scratchpad.
# First call launches a dedicated WezTerm; the matching for_window rule in the
# i3 config floats it, resizes it and sends it to the scratchpad. Subsequent
# calls toggle it on the focused monitor.

if i3-msg -t get_tree | jq -e '.. | select(.window_properties?.class? == "dropdown-terminal")' >/dev/null 2>&1; then
  i3-msg '[class="dropdown-terminal"] scratchpad show' >/dev/null
else
  exec wezterm start --class dropdown-terminal
fi
