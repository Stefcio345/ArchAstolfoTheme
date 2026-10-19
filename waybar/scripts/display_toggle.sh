#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/hardware.sh"

# --- Ensure we talk to the running Hyprland instance ---
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  # Pick the first hypr instance dir owned by this user
  if [ -d /tmp/hypr ]; then
    SIG="$(ls -1 /tmp/hypr 2>/dev/null | head -n1 || true)"
    if [ -n "${SIG:-}" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$SIG"
    fi
  fi
fi

STATE_FILE="/tmp/waybar_display_state"
LOG_FILE="/tmp/waybar_display_toggle.log"

# Adjust to your real outputs/modes
EXTEND_1=${DOTFILES_EXTEND_1:-}
EXTEND_2=${DOTFILES_EXTEND_2:-}
MIRROR_1=${DOTFILES_MIRROR_1:-}
MIRROR_2=${DOTFILES_MIRROR_2:-}
if [[ -z "$EXTEND_1" || -z "$EXTEND_2" || -z "$MIRROR_1" || -z "$MIRROR_2" ]]; then
    notify-send "Display toggle" "Configure monitor names in waybar/local.env first."
    exit 1
fi

log() { echo "[$(date +'%F %T')]" "$@" | tee -a "$LOG_FILE" ; }

run_batch() {
  local batch=$1
  log "[ENV] HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE:-<unset>}"
  log "[CMD] hyprctl --batch \"$batch\""
  if ! hyprctl --batch "$batch" >>"$LOG_FILE" 2>&1; then
    log "[ERR] hyprctl batch failed (exit $?)"
  fi
}

apply_extend() {
  run_batch "keyword monitor $EXTEND_1; keyword monitor $EXTEND_2"
  echo "EXTEND" > "$STATE_FILE"
}

apply_mirror() {
  run_batch "keyword monitor $MIRROR_1; keyword monitor $MIRROR_2"
  echo "MIRROR" > "$STATE_FILE"
}

current="UNKNOWN"
[ -f "$STATE_FILE" ] && current="$(cat "$STATE_FILE")"

if [ "$current" = "MIRROR" ]; then
  apply_extend
else
  apply_mirror
fi
