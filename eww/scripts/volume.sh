#!/usr/bin/env bash
# Current sink volume as an integer percentage (for the eww slider).
# LC_ALL=C: mawk parses numbers via locale-aware strtod (pt_BR uses comma)
LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SINK@ | LC_ALL=C awk '{gsub(",", ".", $2); printf "%d", $2 * 100 + 0.5}'
