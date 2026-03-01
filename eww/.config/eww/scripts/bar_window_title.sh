#!/usr/bin/env bash

# Usage: bar_window_title.sh <monitor_id>
# Outputs the window title for the focused window on the given monitor.
# Uses the same FIFO + socat pattern as bar_wincount.sh for zero idle CPU.

MONITOR_ID="${1:-0}"
PIPE="/tmp/eww-wintitle-pipe-${MONITOR_ID}"
[ -p "$PIPE" ] || mkfifo "$PIPE"

get_title() {
    local info monitor title
    info=$(hyprctl activewindow -j 2>/dev/null)
    if [[ $? -ne 0 ]] || [[ -z "$info" ]] || [[ "$info" == "null" ]]; then
        echo ""
        return
    fi
    monitor=$(echo "$info" | jq -r '.monitor // -1')
    if [[ "$monitor" == "$MONITOR_ID" ]]; then
        echo "$info" | jq -r '.title // ""'
    else
        echo ""
    fi
}

# Print initial title
get_title

# Background: listen for relevant events
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        activewindow\>\>*|closewindow\>\>*|movewindow\>\>*|focusedmon\>\>*) echo "RELOAD" > "$PIPE" ;;
    esac
done &
SOCKET_PID=$!
trap "kill $SOCKET_PID 2>/dev/null; rm -f $PIPE" EXIT

# Hold FIFO open on fd 3 so reads don't block on open()
exec 3<>"$PIPE"

# Main loop: read from FIFO (blocks until data arrives — zero CPU)
while true; do
    if read -r msg <&3; then
        if [ "$msg" = "RELOAD" ]; then
            # Debounce: drain queued events before querying
            while read -r -t 0.05 _ <&3; do :; done
            get_title
        else
            echo "$msg"
        fi
    fi
done
