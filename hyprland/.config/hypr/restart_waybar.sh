#!/usr/bin/env bash

DESKTOP_WINDOWS="desktop-clock-win desktop-stats-left-win desktop-stats-right-win desktop-mpd-win workspace-osd-win"

if [[ -f /tmp/desktop_mode_active ]]; then
    # Desktop mode: restart eww and re-open desktop windows
    eww close $DESKTOP_WINDOWS 2>/dev/null
    eww kill
    sleep 0.5
    eww daemon &
    sleep 1
    eww open-many $DESKTOP_WINDOWS
else
    # Bar mode: restart waybar and eww daemon
    killall waybar
    sleep 0.5
    waybar -c /home/juju/.config/waybar/config-hyprland-top.jsonc -s /home/juju/.config/waybar/style-hyprland-top.css &
    waybar -c /home/juju/.config/waybar/config-hyprland-secondary.jsonc -s /home/juju/.config/waybar/style-hyprland-secondary.css &
    eww kill && eww daemon &
fi
