#!/usr/bin/env bash

PIDFILE="/tmp/idle-inhibit.pid"

toggle() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
    else
        wayland-idle-inhibitor.py &
        echo $! > "$PIDFILE"
    fi
    pkill -RTMIN+8 waybar
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
