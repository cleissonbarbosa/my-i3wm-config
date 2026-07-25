#!/usr/bin/env bash
# Searchable cheat sheet of every binding in the live i3 config.
#
# The list is generated from ~/.config/i3/config itself, so it can never drift
# from the real bindings. The comment sitting above a binding (or the mode it
# belongs to) is used as its description.
# Pressing Enter runs the selected command through i3-msg.
set -uo pipefail

I3_CONFIG="${I3_CONFIG:-$HOME/.config/i3/config}"
THEME="$HOME/.config/rofi/current-theme.rasi"
theme_args=()
[[ -f "$THEME" ]] && theme_args=(-theme "$THEME")

[[ -f "$I3_CONFIG" ]] || { notify-send -u critical "Keybinds" "i3 config não encontrado: $I3_CONFIG"; exit 1; }

# Output lines are "<keys>\t<description>\t<command>"; rofi only ever sees the
# first two columns (see -display-columns below).
list=$(python3 - "$I3_CONFIG" <<'PY'
import re, sys

path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    lines = fh.read().splitlines()

# set $foo <value> definitions, so $mod and friends render as real keys
variables = {}
for line in lines:
    m = re.match(r"\s*set\s+(\$\w+)\s+(.+)$", line)
    if m:
        variables[m.group(1)] = m.group(2).strip()

pretty_mod = {"Mod4": "Super", "Mod1": "Alt", "Mod2": "NumLock", "Mod5": "AltGr"}
pretty_key = {
    "ccedilla": "Ç", "Return": "Enter", "Escape": "Esc", "minus": "-",
    "equal": "=", "period": ".", "comma": ",", "space": "Space",
    "less": "<", "greater": ">", "Print": "PrtSc", "Tab": "Tab",
}

def expand(text):
    # Longest name first, otherwise $ws1 would eat the "$ws1" inside "$ws10"
    for name in sorted(variables, key=len, reverse=True):
        text = text.replace(name, variables[name])
    return text

def render_keys(combo):
    parts = []
    for part in combo.split("+"):
        part = pretty_mod.get(part, pretty_key.get(part, part))
        parts.append(part)
    return " + ".join(parts)

entries = []
mode = None
section = ""      # description carried by the comment block above a group
pending = []      # comment lines currently being collected

for raw in lines:
    line = raw.strip()

    if line.startswith("#"):
        text = line.lstrip("#").strip()
        # Skip separator/banner comments ("--- foo ---", ">>> ... >>>")
        if text and not set(text) <= set("-=<>* "):
            pending.append(text.strip("-= ").strip())
        continue

    # A comment block ends at the first line of actual config: it becomes the
    # description shared by every binding that follows, until the next block.
    if pending:
        section = " ".join(pending)
        pending = []

    m = re.match(r'mode\s+"?([^"{]+)"?\s*\{', line)
    if m:
        # Mode names double as on-screen legends ("Gaps: (i)nner+ ..."), so
        # keep only the label in front of the first ":" or "(".
        mode = re.split(r"[:(]", expand(m.group(1)).strip(), maxsplit=1)[0].strip()
        section = ""
        continue

    if line == "}" and mode:
        mode = None
        section = ""
        continue

    m = re.match(r"bindsym\s+(?:--\S+\s+)*(\S+)\s+(.*)$", line)
    if m:
        raw_keys = expand(m.group(1))
        command = expand(m.group(2)).strip()
        # i3bar scroll guards are not user-facing bindings
        if command == "nop" or raw_keys.startswith("button"):
            continue
        keys = render_keys(raw_keys)
        if mode:
            keys = f"[{mode}]  {keys}"
        entries.append((keys, section or command, command))

seen = set()
unique = []
for entry in entries:
    if entry[0] in seen:
        continue
    seen.add(entry[0])
    unique.append(entry)

width = max((len(k) for k, _, _ in unique), default=0)
for keys, desc, command in unique:
    print(f"{keys.ljust(width)}\t{desc}\t{command}")
PY
) || exit 1

[[ -z "$list" ]] && exit 0

chosen=$(printf '%s\n' "$list" | rofi -dmenu -i -p "󰌌 Atalhos" "${theme_args[@]}" \
  -sep $'\n' -eh 1 \
  -display-columns 1,2 -display-column-separator $'\t' \
  -theme-str 'window { width: 62%; } listview { lines: 16; }') || exit 0

[[ -z "$chosen" ]] && exit 0

# rofi returns the row it displayed; recover the command from the full line.
command=$(printf '%s\n' "$list" | awk -F'\t' -v want="$chosen" '
  { display = $1 "\t" $2 }
  display == want { print $3; exit }')

[[ -n "$command" ]] && i3-msg -- "$command" >/dev/null 2>&1
