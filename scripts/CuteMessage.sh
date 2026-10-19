#!/usr/bin/env zsh

# A single, centered line keeps the welcome balanced at every terminal width.
# Custom messages remain supported without bitmap headers or extra blank rows.
local msg="${1:-♱  welcome home, commander  ♡}"
local width=${COLUMNS:-80}
while (( ${(m)#msg} > width - 4 && ${#msg} > 1 )); do
  msg="${msg[1,-2]}"
done
local msg_width=${(m)#msg}
local padding=$(( (width - msg_width) / 2 ))
(( padding < 0 )) && padding=0

printf '%*s' "$padding" ''
printf '\e[38;2;216;180;195m%s\e[0m\n' "$msg"
