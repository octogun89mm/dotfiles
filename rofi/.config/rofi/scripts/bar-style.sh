#!/usr/bin/env bash

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
MODE_FILE="$STATE_DIR/bar-mode"

mkdir -p "$STATE_DIR"

current="simple"
if [ -f "$MODE_FILE" ]; then
    current=$(tr '[:upper:]' '[:lower:]' < "$MODE_FILE")
fi

selection=$(
    printf '%s\n' \
        "Simple" \
        "Floaty" |
    rofi -dmenu -i -p "Bar style" -no-custom
)

[ -z "$selection" ] && exit 0

case "$selection" in
    "Simple")
        mode="simple"
        ;;
    "Floaty")
        mode="floaty"
        ;;
    *)
        exit 1
        ;;
esac

[ "$mode" = "$current" ] || printf '%s\n' "$mode" > "$MODE_FILE"

"$HOME/.config/hypr/scripts/apply-bar-mode.sh"
exec "$HOME/.config/quickshell/scripts/restart.sh"
