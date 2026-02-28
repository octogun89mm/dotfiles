#!/usr/bin/env bash

# Cycle layout for the focused workspace only

LAYOUTS=(master dwindle scrolling monocle)

# Get active workspace ID and its current layout
eval "$(hyprctl activeworkspace -j | jq -r '@sh "WS_ID=\(.id) current=\(.tiledLayout)"')"
MONITOR_ID=$(hyprctl monitors -j | jq -r ".[] | .activeWorkspace.id as \$ws | select(\$ws == $WS_ID) | .id")

# Find current index and advance
next="master"
for i in "${!LAYOUTS[@]}"; do
    if [[ "${LAYOUTS[$i]}" == "$current" ]]; then
        next="${LAYOUTS[$(( (i + 1) % ${#LAYOUTS[@]} ))]}"
        break
    fi
done

hyprctl keyword workspace "$WS_ID",layout:"$next"
echo "${next^^}" > "/tmp/eww-layout-pipe-${MONITOR_ID}"
notify-send -a "Display Layout" -t 2000 -i preferences-desktop-display "Layout" "${next^^}"
