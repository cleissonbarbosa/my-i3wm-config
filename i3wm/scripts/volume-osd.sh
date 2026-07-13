#!/usr/bin/env bash
# Volume control with a dunst OSD progress bar.
# Usage: volume-osd.sh up|down|mute|mic-mute

case "${1:-}" in
  up)       wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down)     wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute)     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  *) echo "usage: $0 up|down|mute|mic-mute" >&2; exit 1 ;;
esac

if [[ "$1" == "mic-mute" ]]; then
  target="@DEFAULT_AUDIO_SOURCE@"
  label="Microfone"
  icon="󰍬"
  icon_muted="󰍭"
else
  target="@DEFAULT_AUDIO_SINK@"
  label="Volume"
  icon="󰕾"
  icon_muted="󰝟"
fi

info=$(LC_ALL=C wpctl get-volume "$target")
# LC_ALL=C also on awk: mawk parses numbers via strtod, which in pt_BR expects
# a comma as decimal separator and would truncate "0.53" to 0.
vol=$(LC_ALL=C awk '{gsub(",", ".", $2); printf "%d", $2 * 100 + 0.5}' <<<"$info")

if [[ "$info" == *MUTED* ]]; then
  notify-send -a volume-osd -u low -t 1500 \
    -h string:x-dunst-stack-tag:osd \
    "$icon_muted $label mudo"
else
  notify-send -a volume-osd -u low -t 1500 \
    -h string:x-dunst-stack-tag:osd \
    -h int:value:"$vol" \
    "$icon $label: ${vol}%"
fi
