#!/usr/bin/env bash

# Hyprland IPC listener for workspace OSD
# Outputs JSON for eww deflisten: {"visible": true/false, "name": "X"}

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
HIDE_PID=""

hide_after_delay() {
    # Cancel previous hide timer
    if [[ -n "$HIDE_PID" ]] && kill -0 "$HIDE_PID" 2>/dev/null; then
        kill "$HIDE_PID" 2>/dev/null
        wait "$HIDE_PID" 2>/dev/null
    fi

    (
        sleep 0.5
        echo '{"visible": false, "name": "'"$1"'"}'
    ) &
    HIDE_PID=$!
}

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        workspace\>\>*)
            ws_name="${line#workspace>>}"
            echo '{"visible": true, "name": "'"$ws_name"'"}'
            hide_after_delay "$ws_name"
            ;;
    esac
done
