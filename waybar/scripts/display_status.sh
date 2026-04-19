#!/usr/bin/env bash
# Outputs JSON for Waybar (text + tooltip) based on last toggle
STATE_FILE="/tmp/waybar_display_state"

state="UNKNOWN"
[ -f "$STATE_FILE" ] && state="$(cat "$STATE_FILE")"

case "$state" in
  MIRROR)
    text=" Mirror"
    tooltip="HDMI-A-2 mirrors HDMI-A-1"
    class="mirror"
    ;;
  EXTEND)
    text=" Extend"
    tooltip="HDMI-A-1 + HDMI-A-2 extended"
    class="extend"
    ;;
  *)
    # Try a best-effort probe; if it fails, show fallback
    text=" Extend"
    tooltip="Click to toggle mirror/extend"
    class="unknown"
    ;;
esac

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
