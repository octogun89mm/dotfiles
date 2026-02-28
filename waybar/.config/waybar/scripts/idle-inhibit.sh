#!/usr/bin/env bash

PIDFILE="/tmp/idle-inhibit.pid"

toggle() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
        notify-send -a "Idle Inhibitor" -t 2000 -i system-lock-screen "Idle Inhibitor" "OFF — screen will sleep normally"
        eww update bar_idle_inhibit="false"
    else
        wayland-idle-inhibitor.py &
        echo $! > "$PIDFILE"
        notify-send -a "Idle Inhibitor" -t 2000 -i system-lock-screen "Idle Inhibitor" "ON — screen will stay awake"
        eww update bar_idle_inhibit="true"
    fi
}

status() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        printf '{"alt": "\U000f0208", "class": "activated", "tooltip": "Idle inhibitor: ON"}\n'
    else
        rm -f "$PIDFILE"
        printf '{"alt": "\U000f0209", "class": "deactivated", "tooltip": "Idle inhibitor: OFF"}\n'
    fi
}

case "$1" in
    toggle) toggle ;;
    *) status ;;
esac
