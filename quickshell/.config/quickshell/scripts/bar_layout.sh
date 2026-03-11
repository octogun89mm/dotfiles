#!/usr/bin/env bash

MONITOR_NAME="${1:-}"
MONITOR_ID="${2:-}"
PIPE="/tmp/quickshell-layout-pipe-${MONITOR_NAME//[^[:alnum:]_-]/_}"
LEGACY_PIPE="/tmp/eww-layout-pipe-${MONITOR_ID}"
POLL_SECONDS=2

[ -n "$MONITOR_NAME" ] || exit 1
[ -p "$PIPE" ] || mkfifo "$PIPE"

get_layout() {
    local ws_id
    ws_id=$(hyprctl monitors -j | jq -r --arg name "$MONITOR_NAME" '.[] | select(.name == $name) | .activeWorkspace.id')
    if [ -n "$ws_id" ] && [ "$ws_id" != "null" ]; then
        hyprctl workspaces -j | jq -r --argjson ws_id "$ws_id" '.[] | select(.id == $ws_id) | .tiledLayout' | tr '[:lower:]' '[:upper:]'
    fi
}

get_layout

# Hyprland does not emit a dedicated socket2 event for workspace tiledLayout changes.
# Refresh immediately on monitor/workspace-related events and use a light polling
# fallback so layout flips on the current workspace still show up.
socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        workspace\>\>*|workspacev2\>\>*|focusedmon\>\>*|focusedmonv2\>\>*|moveworkspace\>\>*|moveworkspacev2\>\>*|configreloaded*)
            echo "RELOAD" > "$PIPE"
            ;;
    esac
done &
SOCKET_PID=$!

if [ -n "$MONITOR_ID" ]; then
    [ -p "$LEGACY_PIPE" ] || mkfifo "$LEGACY_PIPE"
    while read -r _; do
        echo "RELOAD" > "$PIPE"
    done < "$LEGACY_PIPE" &
    LEGACY_PID=$!
else
    LEGACY_PID=""
fi

while true; do
    sleep "$POLL_SECONDS"
    echo "POLL" > "$PIPE"
done &
POLL_PID=$!

trap "kill $SOCKET_PID $LEGACY_PID $POLL_PID 2>/dev/null; rm -f '$PIPE'" EXIT

exec 3<>"$PIPE"

while true; do
    if read -r msg <&3; then
        if [ "$msg" = "RELOAD" ] || [ "$msg" = "POLL" ]; then
            while read -r -t 0.05 _ <&3; do :; done
            get_layout
        else
            echo "$msg"
        fi
    fi
done
