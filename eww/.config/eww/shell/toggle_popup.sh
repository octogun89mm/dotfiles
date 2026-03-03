#!/usr/bin/env bash

# Toggle eww bar popup visibility, targeting the correct monitor
MONITOR="${1:-0}"
CURRENT=$(eww get popup_visible)

if [ "$CURRENT" = "true" ]; then
    CURRENT_MON=$(eww get popup_monitor)
    if [ "$CURRENT_MON" = "$MONITOR" ]; then
        eww update popup_visible=false
    else
        eww update popup_monitor="$MONITOR"
    fi
else
    eww update popup_monitor="$MONITOR" popup_visible=true
fi
