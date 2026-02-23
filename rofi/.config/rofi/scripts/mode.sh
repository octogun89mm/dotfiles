#!/usr/bin/env bash

# Rofi mode picker for bar/desktop mode switching

if [ -z "$1" ]; then
    if [[ -f /tmp/desktop_mode_active ]]; then
        echo "Switch to Bar Mode"
    else
        echo "Switch to Desktop Mode"
    fi
    exit 0
fi

case "$1" in
    "Switch to Desktop Mode")
        ~/.config/eww/scripts/mode_switch.sh desktop
        ;;
    "Switch to Bar Mode")
        ~/.config/eww/scripts/mode_switch.sh bar
        ;;
    *)
        exit 1
        ;;
esac

exit 0
