#!/usr/bin/env bash
# Screen recording toggle built on ffmpeg's x11grab.
# Usage: screen-record.sh full|monitor [--audio]
#
# Spectacle cannot record: recording only landed in the 24.08 series and is
# built on KWin/PipeWire screencasting, so it is not an option under i3 on X11.
#
# The same binding starts and stops. While a recording is running the mode
# argument is ignored and ffmpeg is asked to finalize the file instead, so one
# key can drive the whole cycle.

set -euo pipefail

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/screen-record.pid"
OUTDIR="$HOME/Videos"

notify() { notify-send -a screen-record -u "$1" -t 2500 "$2" "${3:-}"; }

die() { notify critical "󰑊 Gravação de tela" "$1"; echo "$1" >&2; exit 1; }

# --- stop an in-flight recording -------------------------------------------
if [[ -s "$PIDFILE" ]]; then
  pid=$(sed -n 1p "$PIDFILE")
  file=$(sed -n 2p "$PIDFILE")
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    # SIGTERM, not SIGKILL: ffmpeg has to write the moov atom or the mp4 is
    # unplayable. And not SIGINT either: bash sets SIGINT to SIG_IGN for
    # background jobs of a non-interactive shell, so it is unreliable here.
    kill -TERM "$pid"
    stopped=false
    for _ in $(seq 1 100); do
      kill -0 "$pid" 2>/dev/null || { stopped=true; break; }
      sleep 0.1
    done
    if ! $stopped; then
      # Out of patience: the file will likely be truncated, so say so instead
      # of reporting a success that did not happen.
      kill -KILL "$pid" 2>/dev/null || true
      rm -f "$PIDFILE"
      notify critical "󰑊 Gravação de tela" "ffmpeg não respondeu, vídeo pode estar corrompido"
      exit 1
    fi
    rm -f "$PIDFILE"
    if [[ -s "$file" ]]; then
      notify low "󰑊 Gravação finalizada" "$(basename "$file")"
    else
      notify critical "󰑊 Gravação de tela" "Arquivo vazio, algo falhou"
    fi
    exit 0
  fi
  # Stale file (previous ffmpeg died on its own).
  rm -f "$PIDFILE"
fi

# --- start a new recording --------------------------------------------------
audio=false
mode=""
for arg in "$@"; do
  case "$arg" in
    full|monitor) mode="$arg" ;;
    --audio)      audio=true ;;
    *) echo "usage: $0 full|monitor [--audio]" >&2; exit 1 ;;
  esac
done
[[ -n "$mode" ]] || { echo "usage: $0 full|monitor [--audio]" >&2; exit 1; }

command -v ffmpeg >/dev/null || die "ffmpeg não instalado"

if [[ "$mode" == "full" ]]; then
  # "Screen 0: ... current 3840 x 1080, maximum ..." spans every output.
  read -r w h < <(xrandr --query | sed -n 's/.*current \([0-9]\+\) x \([0-9]\+\).*/\1 \2/p')
  x=0; y=0
else
  output=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')
  geo=$(xrandr --query | sed -n "s/^$output connected \(primary \)\?\([0-9]\+x[0-9]\++[0-9]\++[0-9]\+\).*/\2/p")
  [[ -n "$geo" ]] || die "não achei a geometria de $output"
  w=${geo%%x*}; rest=${geo#*x}
  h=${rest%%+*}; rest=${rest#*+}
  x=${rest%%+*}; y=${rest#*+}
fi
[[ -n "${w:-}" && -n "${h:-}" ]] || die "não consegui determinar a resolução"

# libx264 with yuv420p rejects odd dimensions.
w=$(( w / 2 * 2 )); h=$(( h / 2 * 2 ))

mkdir -p "$OUTDIR"
file="$OUTDIR/screencast-$(date +%Y%m%d_%H%M%S).mp4"

audio_args=()
$audio && audio_args=(-f pulse -i default -c:a aac -b:a 128k)

ffmpeg -hide_banner -loglevel error \
  -f x11grab -framerate 30 -video_size "${w}x${h}" -i "${DISPLAY}+${x},${y}" \
  "${audio_args[@]}" \
  -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p \
  "$file" </dev/null >/dev/null 2>&1 &

printf '%s\n%s\n' "$!" "$file" > "$PIDFILE"
notify low "󰑊 Gravando ${w}x${h}" "Mesmo atalho para parar"
