#!/usr/bin/env bash

# Hyprland IPC listener for keyboard layout changes
# Outputs short layout name (EN, FR, etc.) for eww deflisten

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

# Get initial layout from hyprctl
initial=$(hyprctl devices -j | jq -r '[.keyboards[] | select(.main == true)] | .[0].active_keymap // "English (US)"')
shorten_layout "$initial"

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        activelayout\>\>*)
            # Format: activelayout>>KEYBOARD,LAYOUT_NAME
            layout="${line#*,}"
            shorten_layout "$layout"
            ;;
    esac
done
