#!/usr/bin/env bash

STATE_FILE="/tmp/monitor_brightness"
source "$(dirname -- "${BASH_SOURCE[0]}")/hardware.sh"
BUS1=${DOTFILES_DDC_BUS1:-}
BUS2=${DOTFILES_DDC_BUS2:-}
STEP=10
LAST_DDC_CALL="/tmp/monitor_brightness_ddc_last"
DDC_COOLDOWN=0.2 # seconds

init() {
    local cur
	cur="$(ddcutil getvcp 10 --terse 2>/dev/null | awk '$1=="VCP" && $2=="10" {print $4}')"

    if [[ "$cur" =~ ^[0-9]+$ ]]; then
        echo "$cur" > "$STATE_FILE"
    else
        echo 50 > "$STATE_FILE"
    fi
}

get_cached_brightness() {
    [[ -f "$STATE_FILE" ]] || init

    local cur="$(cat "$STATE_FILE" 2>/dev/null)"
    [[ "$cur" =~ ^[0-9]+$ ]] && echo "$cur" || echo 50
}

can_make_ddc_call() {
    local now=$(date +%s.%N)
    local last_ddc=0
    if [[ -f "$LAST_DDC_CALL" ]]; then
        last_ddc=$(cat "$LAST_DDC_CALL")
    fi
    local diff=$(echo "$now - $last_ddc" | bc)
    if (( $(echo "$diff > $DDC_COOLDOWN" | bc -l) )); then
        echo "$now" > "$LAST_DDC_CALL"
        return 0
    else
        return 1
    fi
}

# Queue DDC call with debounce
queue_ddc_call() {
    local val="$1"
    local pidfile="/tmp/monitor_brightness_ddc_pid"

    # Kill previous background process if still running
    if [[ -f "$pidfile" ]]; then
        local oldpid=$(cat "$pidfile")
        kill "$oldpid" 2>/dev/null || true
    fi

    # Start new background process
    (
        sleep "$DDC_COOLDOWN"
        if can_make_ddc_call; then
            if [[ -n "$BUS1" ]]; then
                ddcutil setvcp 10 "$val" --bus="$BUS1" --noverify --sleep-multiplier 0.1 >/dev/null 2>&1
            else
                ddcutil setvcp 10 "$val" --noverify --sleep-multiplier 0.1 >/dev/null 2>&1
            fi
            if [[ -n "$BUS2" ]]; then
                ddcutil setvcp 10 "$val" --bus="$BUS2" --noverify --sleep-multiplier 0.1 >/dev/null 2>&1
            fi
        fi
    ) &
    echo $! > "$pidfile"
}

set_brightness() {
    local val="$1"
    local cur

    [[ "$val" =~ ^[0-9]+$ ]] || return 1
    (( val < 0 )) && val=0
    (( val > 100 )) && val=100

    cur="$(get_cached_brightness)"
    (( val == cur )) && return 0

    echo "$val" > "$STATE_FILE"

    # Queue DDC call to be executed after cooldown
    queue_ddc_call "$val"
}

change_brightness() {
    local cur new
    cur="$(get_cached_brightness)"
    if [[ "$1" == "+" ]]; then
        new=$((cur + STEP))
    else
        new=$((cur - STEP))
    fi
    (( new < 0 )) && new=0
    (( new > 100 )) && new=100
    set_brightness "$new"
}

print_status() {
    local avg icon class
    avg="$(get_cached_brightness)"
    if (( avg >= 70 )); then
        icon="󰃠"   # high brightness
        class="high"
    elif (( avg >= 35 )); then
        icon="󰃟"   # medium
        class="medium"
    else
        icon="󰃞"   # low
        class="low"
    fi
    printf '{"text":"%s %d%%","class":"%s","percentage":%d}\n' \
        "$icon" "$avg" "$class" "$avg"
}


# Handle arguments
case "$1" in
    up) change_brightness "+" ;;
    down) change_brightness "-" ;;
    set) set_brightness "$2" ;;
    *) print_status ;;
esac
