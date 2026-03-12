#!/usr/bin/env bash

set -u

MONITOR_NAME="${1:-}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PIPE="$RUNTIME_DIR/quickshell-layout-pipe-${MONITOR_NAME//[^[:alnum:]_-]/_}"
POLL_SECONDS=3

[ -n "$MONITOR_NAME" ] || exit 1
[ -p "$PIPE" ] || mkfifo "$PIPE"

trap 'rm -f "$PIPE"; kill 0' EXIT HUP INT TERM PIPE

get_layout() {
    local ws_id
    ws_id=$(hyprctl monitors -j | jq -r --arg name "$MONITOR_NAME" '.[] | select(.name == $name) | .activeWorkspace.id')
    if [ -n "$ws_id" ] && [ "$ws_id" != "null" ]; then
        hyprctl workspaces -j | jq -r --argjson ws_id "$ws_id" '.[] | select(.id == $ws_id) | .tiledLayout' | tr '[:lower:]' '[:upper:]'
    fi
}

get_layout

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
        workspace\>\>*|workspacev2\>\>*|focusedmon\>\>*|focusedmonv2\>\>*|moveworkspace\>\>*|moveworkspacev2\>\>*|configreloaded*)
            echo "RELOAD" > "$PIPE"
            ;;
    esac
done &

while true; do
    sleep "$POLL_SECONDS"
    echo "POLL" > "$PIPE"
done &

exec 3<>"$PIPE"

while true; do
    if read -r msg <&3; then
        if [ "$msg" = "RELOAD" ] || [ "$msg" = "POLL" ]; then
            while read -r -t 0.05 _ <&3; do :; done
            get_layout
        else
            echo "$msg"
        fi
    else
        sleep 1
    fi
done
