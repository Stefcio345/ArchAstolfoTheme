#!/usr/bin/env zsh

# Default message
local default_msg="♡  ♡  ♡  ♡  ( ˘ ³˘)♥  UwU~ hewwooo commander-sama~ (˶˃ᵕ˂˶) nyaaa~  ♡  ♡  ♡  ♡"

# Use argument if provided, otherwise default
local msg="${1:-$default_msg}"

# Terminal width
local width=${COLUMNS:-$(tput cols)}

# Compute display width
local msg_width
msg_width=$(
  MSG="$msg" python3 - <<'PY'
import os, unicodedata

s = os.environ["MSG"]

def ch_width(c):
    if unicodedata.combining(c):
        return 0
    if unicodedata.east_asian_width(c) in ("W", "F"):
        return 2
    return 1

print(sum(ch_width(c) for c in s))
PY
)

# If message is wider than terminal, take centered slice
if (( msg_width > width )); then
  msg=$(
    MSG="$msg" WIDTH="$width" TOTAL="$msg_width" python3 - <<'PY'
import os, unicodedata

s = os.environ["MSG"]
max_width = int(os.environ["WIDTH"])
total_width = int(os.environ["TOTAL"])

def ch_width(c):
    if unicodedata.combining(c):
        return 0
    if unicodedata.east_asian_width(c) in ("W", "F"):
        return 2
    return 1

# Convert string to (char, width) list
chars = [(c, ch_width(c)) for c in s]

# Calculate centered window
start_width = (total_width - max_width) // 2
end_width = start_width + max_width

cur = 0
out = []

for c, w in chars:
    next_cur = cur + w
    if next_cur > start_width and cur < end_width:
        out.append(c)
    cur = next_cur

print("".join(out))
PY
  )
  msg_width=$width
fi

# Center padding (only applies if it fits)
local padding=$(( (width - msg_width) / 2 ))
(( padding < 0 )) && padding=0

# Separator line
local line="${(r:${msg_width}::─:)}"

clear
printf '\e[?7l'   # disable wrap

printf "%*s" $padding ""
print -P "%F{#3a3a40}${line}%f"

printf "%*s" $padding ""
print -P "%F{#f38ba8}${msg}%f"

printf "%*s" $padding ""
print -P "%F{#3a3a40}${line}%f"

print ""

printf '\e[?7h'   # re-enable wrap
