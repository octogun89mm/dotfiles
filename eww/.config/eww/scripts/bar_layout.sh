#!/usr/bin/env bash

# Usage: bar_layout.sh <monitor_id>
# Each monitor instance gets its own FIFO and tracks its own workspace layout.

MONITOR_ID="${1:-0}"
PIPE="/tmp/eww-layout-pipe-${MONITOR_ID}"
[ -p "$PIPE" ] || mkfifo "$PIPE"

get_layout() {
    local ws_id
    ws_id=$(hyprctl monitors -j | jq -r ".[] | select(.id == $MONITOR_ID) | .activeWorkspace.id")
    if [ -n "$ws_id" ]; then
        hyprctl workspaces -j | jq -r ".[] | select(.id == $ws_id) | .tiledLayout" | tr '[:lower:]' '[:upper:]'
    fi
}

# Print initial layout
get_layout

# Background: listen for workspace/monitor focus changes and config reloads
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        workspace\>\>*|focusedmon\>\>*|configreloaded*) echo "RELOAD" > "$PIPE" ;;
    esac
done &
SOCKET_PID=$!
trap "kill $SOCKET_PID 2>/dev/null; rm -f $PIPE" EXIT

# Main loop: read from FIFO (blocks until data arrives — zero CPU)
while true; do
    if read -r msg < "$PIPE"; then
        if [ "$msg" = "RELOAD" ]; then
            get_layout
        else
            echo "$msg"
        fi
    fi
done
