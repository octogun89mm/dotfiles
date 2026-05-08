#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/hypridle-suspend-disabled"

status() {
    if [[ -f "$STATE_FILE" ]]; then
        printf '{"active":false,"status":"disabled","tooltip":"Automatic suspend: OFF"}\n'
    else
        printf '{"active":true,"status":"enabled","tooltip":"Automatic suspend: ON"}\n'
    fi
}

toggle() {
    mkdir -p "$(dirname "$STATE_FILE")"

    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        notify-send -a "Hypridle" -t 2000 "Automatic suspend" "Enabled" 2>/dev/null || true
    else
        : > "$STATE_FILE"
        notify-send -a "Hypridle" -t 2000 "Automatic suspend" "Disabled" 2>/dev/null || true
    fi
}

suspend_if_enabled() {
    if [[ -f "$STATE_FILE" ]]; then
        exit 0
    fi

    exec systemctl suspend
}

case "${1:-suspend}" in
    status) status ;;
    toggle) toggle ;;
    suspend) suspend_if_enabled ;;
    *) suspend_if_enabled ;;
esac
