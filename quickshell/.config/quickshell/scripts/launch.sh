#!/usr/bin/env bash

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
MODE_FILE="$STATE_DIR/bar-mode"

mkdir -p "$STATE_DIR"

mode="simple"
if [ -f "$MODE_FILE" ]; then
    mode=$(tr '[:upper:]' '[:lower:]' < "$MODE_FILE")
fi

case "$mode" in
    floaty)
        ;;
    *)
        mode="simple"
        ;;
esac

printf '%s\n' "$mode" > "$MODE_FILE"
export QUICKSHELL_BAR_MODE="$mode"

exec quickshell -d
