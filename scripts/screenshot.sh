#!/usr/bin/env bash
if command -v jushot >/dev/null 2>&1; then
    exec jushot "$@"
fi
exec hyprshot -m region --clipboard-only "$@"
