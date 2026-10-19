#!/usr/bin/env bash
if command -v seal >/dev/null 2>&1; then
    exec seal "$@"
fi
exec thunar "$@"
