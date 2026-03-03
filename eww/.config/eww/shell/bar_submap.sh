#!/usr/bin/env bash

# Hyprland IPC listener for submap changes
# Outputs submap name (empty string when reset) for eww deflisten

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Initial state: no submap
echo ""

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        submap\>\>*)
            submap="${line#submap>>}"
            echo "$submap"
            ;;
    esac
done
