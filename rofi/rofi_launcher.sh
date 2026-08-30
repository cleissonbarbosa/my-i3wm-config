#!/usr/bin/env bash
# Application launcher (windows + desktop apps + commands).
rofi -show combi -combi-modes "window,drun,run" -modes combi -show-icons \
  -theme "$HOME/.config/rofi/current-theme.rasi" \
  -display-combi "󰍉 " -display-run "󰆍 " -display-window "󰖯 " -display-drun "󰀻 "
