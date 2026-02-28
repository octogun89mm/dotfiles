#!/usr/bin/env bash

# Usage: bar_wincount.sh <monitor_id>
# Outputs the window count for the active workspace on the given monitor.
# Uses the same FIFO pattern as bar_layout.sh for zero idle CPU.

MONITOR_ID="${1:-0}"
PIPE="/tmp/eww-wincount-pipe-${MONITOR_ID}"
[ -p "$PIPE" ] || mkfifo "$PIPE"

get_wincount() {
    local ws_id
    ws_id=$(hyprctl monitors -j | jq -r ".[] | select(.id == $MONITOR_ID) | .activeWorkspace.id")
    if [ -n "$ws_id" ]; then
        hyprctl workspaces -j | jq -r ".[] | select(.id == $ws_id) | .windows"
    else
        echo "0"
    fi
}

# Print initial count
get_wincount

# Background: listen for relevant events
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        openwindow\>\>*|closewindow\>\>*|movewindow\>\>*|workspace\>\>*|focusedmon\>\>*) echo "RELOAD" > "$PIPE" ;;
    esac
done &
SOCKET_PID=$!
trap "kill $SOCKET_PID 2>/dev/null; rm -f $PIPE" EXIT

# Main loop: read from FIFO (blocks until data arrives — zero CPU)
while true; do
    if read -r msg < "$PIPE"; then
        if [ "$msg" = "RELOAD" ]; then
            get_wincount
        else
            echo "$msg"
        fi
    fi
done
