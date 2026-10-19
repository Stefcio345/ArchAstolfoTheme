#!/usr/bin/env bash

PROC_NAME="wvkbd-mobintl"

if pgrep -x "$PROC_NAME" >/dev/null; then
  pkill -x "$PROC_NAME"
else
  "$PROC_NAME" -H 450 -L 350 --fn "DejaVu Sans 28" &
fi
