#!/usr/bin/env bash

# Toggle between Waybar (bar mode) and EWW desktop mode

DESKTOP_WINDOWS="desktop-clock-win desktop-stats-left-win desktop-stats-right-win desktop-mpd-win workspace-osd-win workspace-list-win"
STATE_FILE="/tmp/desktop_mode_active"

to_desktop() {
    killall waybar 2>/dev/null
    sleep 0.3
    eww open-many $DESKTOP_WINDOWS
    touch "$STATE_FILE"
}

to_bar() {
    eww close $DESKTOP_WINDOWS 2>/dev/null
    rm -f "$STATE_FILE"
    sleep 0.3
    waybar -c /home/juju/.config/waybar/config-hyprland-top.jsonc \
           -s /home/juju/.config/waybar/style-hyprland-top.css &
}

status() {
    if [[ -f "$STATE_FILE" ]]; then
        echo "desktop"
    else
        echo "bar"
    fi
}

case "${1:-toggle}" in
    desktop)  to_desktop ;;
    bar)      to_bar ;;
    toggle)
        if [[ -f "$STATE_FILE" ]]; then
            to_bar
        else
            to_desktop
        fi
        ;;
    status) status ;;
    *) echo "Usage: $0 {desktop|bar|toggle|status}" >&2; exit 1 ;;
esac
