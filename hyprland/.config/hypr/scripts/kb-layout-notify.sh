#!/usr/bin/env bash

# Listen for Hyprland keyboard layout changes and send notifications

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

shorten_layout() {
    local layout="$1"
    case "$layout" in
        *English*|*us*) echo "EN" ;;
        *French*|*Canadian*|*ca*) echo "FR" ;;
        *German*|*de*) echo "DE" ;;
        *Spanish*|*es*) echo "ES" ;;
        *) echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]' ;;
    esac
}

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        activelayout\>\>*)
            layout="${line#*,}"
            short=$(shorten_layout "$layout")
            notify-send -a "Keyboard" -t 2000 -i input-keyboard "Keyboard Layout" "$short ($layout)"
            ;;
    esac
done
