#!/bin/bash

RECORDING_FILE="$HOME/Videos/recording_$(date +%Y-%m-%d_%H-%M-%S).gif"
PID_FILE="/tmp/wf-recorder.pid"

# Check if wf-recorder is running
if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
    echo "Stopping wf-recorder..."
    kill "$(cat $PID_FILE)"
    rm "$PID_FILE"
    notify-send "Recording Stopped"
else
    echo "Starting wf-recorder..."
    GEOM=$(slurp)
    if [ -z "$GEOM" ]; then
        echo "No region selected. Exiting."
        exit 1
    fi
    wf-recorder -g "$GEOM" -f "$RECORDING_FILE" -F fps=30 -c gif &
    echo $! > "$PID_FILE"
    notify-send "Recording Started" "Saving to $RECORDING_FILE"
fi
