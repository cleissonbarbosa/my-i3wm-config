#!/usr/bin/env bash
# Launcher that runs the chosen command with sudo, asking the password via rofi-askpass.
export SUDO_ASKPASS="$HOME/.local/bin/rofi-askpass"
rofi -show combi -combi-modes "window,drun,run" -modes combi -show-icons \
  -run-command "sudo -A {cmd}" \
  -theme "$HOME/.config/rofi/current-theme.rasi" \
  -display-combi "🔍: " -display-run "Run SUDO: " -display-window "Windows SUDO: " -display-drun "Apps SUDO: "
