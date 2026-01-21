#!/usr/bin/env bash

# If no argument, print menu options
if [ -z "$1" ]; then
    echo "Shutdown"
    echo "Reboot"
    echo "Logout"
    exit 0
fi

# Process selection
case "$1" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Logout")
        swaymsg exit
        ;;
    *)
        exit 1
        ;;
esac

exit 0
