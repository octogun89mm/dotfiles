#!/usr/bin/env zsh

set -eu

MONITOR_NAME="${1:-}"

[ -n "$MONITOR_NAME" ] || exit 1

ws_id=$(hyprctl monitors -j | jq -r --arg name "$MONITOR_NAME" '.[] | select(.name == $name) | .activeWorkspace.id')

if [ -z "$ws_id" ] || [ "$ws_id" = "null" ]; then
    exit 0
fi

hyprctl workspaces -j \
    | jq -r --arg ws_id "$ws_id" '.[] | select((.id | tostring) == $ws_id) | .tiledLayout' \
    | tr '[:lower:]' '[:upper:]'
