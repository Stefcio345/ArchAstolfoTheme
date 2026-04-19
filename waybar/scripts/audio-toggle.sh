#!/usr/bin/env bash

get_sink_id() {
    local pattern="$1"

    wpctl status | awk -v pattern="$pattern" '
        /├─ Sinks:/ { in_sinks=1; next }
        /├─ Sources:/ { in_sinks=0 }
        in_sinks && $0 ~ pattern {
            if (match($0, /[0-9]+\./)) {
                id = substr($0, RSTART, RLENGTH)
                sub(/\./, "", id)
                print id
                exit
            }
        }
    '
}

get_current_sink_id() {
    wpctl status | awk '
        /├─ Sinks:/ { in_sinks=1; next }
        /├─ Sources:/ { in_sinks=0 }
        in_sinks && /\*/ {
            if (match($0, /[0-9]+\./)) {
                id = substr($0, RSTART, RLENGTH)
                sub(/\./, "", id)
                print id
                exit
            }
        }
    '
}

SPEAKER_ID=$(get_sink_id "Starship/Matisse HD Audio Controller Analog Stereo")
HEADPHONES_ID=$(get_sink_id "PRO Analog Stereo")
CURRENT_ID=$(get_current_sink_id)

[ -n "$SPEAKER_ID" ] || exit 1
[ -n "$HEADPHONES_ID" ] || exit 1
[ -n "$CURRENT_ID" ] || exit 1

if [ "$CURRENT_ID" = "$SPEAKER_ID" ]; then
    wpctl set-default "$HEADPHONES_ID"
else
    wpctl set-default "$SPEAKER_ID"
fi
