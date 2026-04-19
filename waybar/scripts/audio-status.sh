#!/usr/bin/env bash

CURRENT_ID=$(
    wpctl status | awk '
        /Sinks:/ { in_sinks=1; next }
        /Sources:/ { if (in_sinks) exit }
        in_sinks && /\*/ {
            if (match($0, /[0-9]+\./)) {
                id = substr($0, RSTART, RLENGTH)
                sub(/\./, "", id)
                print id
                exit
            }
        }
    '
)

HEADPHONES_ID=$(
    wpctl status | awk '
        /Sinks:/ { in_sinks=1; next }
        /Sources:/ { if (in_sinks) exit }
        in_sinks && /PRO Analog Stereo/ {
            if (match($0, /[0-9]+\./)) {
                id = substr($0, RSTART, RLENGTH)
                sub(/\./, "", id)
                print id
                exit
            }
        }
    '
)

[ -n "$CURRENT_ID" ] && [ "$CURRENT_ID" = "$HEADPHONES_ID" ] && echo "" || echo ""
