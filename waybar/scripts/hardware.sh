#!/usr/bin/env bash
# Source this file; optional per-machine overrides never enter Git.
hardware_file="$(dirname -- "${BASH_SOURCE[0]}")/../local.env"
if [[ -f "$hardware_file" ]]; then
    source "$hardware_file"
fi
unset hardware_file
