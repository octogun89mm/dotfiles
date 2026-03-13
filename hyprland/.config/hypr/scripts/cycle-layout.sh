#!/usr/bin/env bash

# Cycle layout for the focused workspace only

LAYOUTS=(master dwindle scrolling monocle)

# Get active workspace ID and its current layout
eval "$(hyprctl activeworkspace -j | jq -r '@sh "WS_ID=\(.id) current=\(.tiledLayout)"')"

# Find current index and advance
next="master"
for i in "${!LAYOUTS[@]}"; do
    if [[ "${LAYOUTS[$i]}" == "$current" ]]; then
        next="${LAYOUTS[$(( (i + 1) % ${#LAYOUTS[@]} ))]}"
        break
    fi
done

hyprctl keyword workspace "$WS_ID",layout:"$next"

REFRESH_STAMP="/tmp/quickshell-layout-refresh.state"
date +%s > "$REFRESH_STAMP"
