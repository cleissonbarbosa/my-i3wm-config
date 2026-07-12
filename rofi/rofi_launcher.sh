#!/usr/bin/env bash
# Application launcher (windows + desktop apps + commands).
rofi -show combi -combi-modi "window,drun,run" -modi combi -show-icons \
  -theme "$HOME/.config/rofi/dracula.rasi" \
  -display-combi "🔍: " -display-run "Run: " -display-window "Windows: " -display-drun "App: "
