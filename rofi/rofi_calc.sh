#!/usr/bin/env bash
# Minimal rofi calculator (python eval, math functions available).
# Type an expression, Enter shows the result, Enter again copies it.

THEME="$HOME/.config/rofi/current-theme.rasi"

expr_in=$(rofi -dmenu -p "󰃬 " -theme "$THEME" \
  -theme-str 'listview { lines: 0; } entry { placeholder: "Ex.: (2**10) / 4 + sqrt(9)"; }') || exit 0
[[ -z "$expr_in" ]] && exit 0

result=$(EXPR="$expr_in" python3 -c '
import os
from math import *
print(eval(os.environ["EXPR"]))
' 2>&1) || result="Erro: expressão inválida"

sel=$(printf '%s' "$result" | rofi -dmenu -p "= " -theme "$THEME" \
  -theme-str 'listview { lines: 1; } entry { placeholder: "Enter copia o resultado"; }') || exit 0

if [[ -n "$sel" ]]; then
  printf '%s' "$sel" | xclip -selection clipboard
  notify-send -a rofi-calc -u low -t 2000 "󰃬 Calc" "Copiado: $sel"
fi
