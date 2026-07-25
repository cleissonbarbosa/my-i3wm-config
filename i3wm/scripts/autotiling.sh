#!/usr/bin/env bash
# Starts autotiling (new windows split along the longest side of the focused
# container) unless it is already running.
#
# It has to be idempotent rather than "kill then restart": autotiling talks to
# i3 over IPC and its connection survives an in-place `i3 restart`, while the
# i3 config calls this from exec_always, i.e. on every reload.
#
# Matching by full command line is deliberate — autotiling is a Python entry
# point, so `pgrep -x autotiling` never finds it. The pattern is anchored on
# the executable name so it cannot match this script itself.
set -uo pipefail

command -v autotiling >/dev/null 2>&1 || exit 0

if pgrep -f '/bin/autotiling( |$)' >/dev/null 2>&1; then
  exit 0
fi

exec autotiling
