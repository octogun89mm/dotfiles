#!/usr/bin/env bash

set -euo pipefail

MONITOR_NAME="${1:-}"

[ -n "$MONITOR_NAME" ] || exit 1

workspace_id=$(
    hyprctl monitors -j \
        | jq -r --arg name "$MONITOR_NAME" '.[] | select(.name == $name) | .activeWorkspace.id'
)

if [ -z "$workspace_id" ] || [ "$workspace_id" = "null" ]; then
    printf '{"count":0,"layout":""}\n'
    exit 0
fi

hyprctl workspaces -j \
    | jq -c --arg workspace_id "$workspace_id" '
        (
          first(
            .[]
            | select((.id | tostring) == $workspace_id)
            | {
                count: (.windows // 0),
                layout: ((.tiledLayout // "") | ascii_upcase)
              }
          )
        ) // {
          count: 0,
          layout: ""
        }
    '
