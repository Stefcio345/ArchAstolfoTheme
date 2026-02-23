#!/usr/bin/env zsh

# Default message
local default_msg="♡  ♡  ♡  ♡  ( ˘ ³˘)♥  UwU~ hewwooo commander-sama~ (˶˃ᵕ˂˶) nyaaa~  ♡  ♡  ♡  ♡"

# Use argument if provided, otherwise default
local msg="${1:-$default_msg}"

# Terminal width
local width=${COLUMNS:-$(tput cols)}

# Compute display width (Unicode-safe-ish)
local msg_width
msg_width=$(
  MSG="$msg" python3 - <<'PY'
import os, unicodedata
s = os.environ["MSG"]

def ch_width(c: str) -> int:
    if unicodedata.combining(c):
        return 0
    if unicodedata.east_asian_width(c) in ("W", "F"):
        return 2
    return 1

print(sum(ch_width(c) for c in s))
PY
)

# Center padding
local padding=$(( (width - msg_width) / 2 ))
(( padding < 0 )) && padding=0

# Build separator line matching message width
local line="${(r:${msg_width}::─:)""}"

# Print block
clear

printf "%*s" $padding ""
print -P "%F{#3a3a40}${line}%f"

printf "%*s" $padding ""
print -P "%F{#f38ba8}${msg}%f"

printf "%*s" $padding ""
print -P "%F{#3a3a40}${line}%f"

print ""
