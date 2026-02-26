#!/usr/bin/env bash

# Hyprland IPC listener for bar workspaces
# Outputs JSON array of workspace objects for eww deflisten

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Predefined workspace list: id -> label
declare -A WS_LABELS=(
    [1]="A1" [2]="A2" [3]="A3" [4]="A4" [5]="A5" [6]="A6"
    [7]="B7" [8]="B8" [9]="B9" [10]="B0"
)

query_workspaces() {
    local workspaces active_id monitors

    workspaces=$(hyprctl workspaces -j)
    active_id=$(hyprctl activeworkspace -j | jq '.id')
    monitors=$(hyprctl monitors -j)

    # Get visible workspace IDs (one per monitor)
    local visible_ids
    visible_ids=$(echo "$monitors" | jq '[.[].activeWorkspace.id]')

    # Get IDs of special workspaces
    local special_names='["special:dropdown","special:magic"]'

    echo "$workspaces" | jq -c \
        --argjson active "$active_id" \
        --argjson visible "$visible_ids" \
        --argjson special "$special_names" '

        # Build a set of occupied workspace IDs
        ([.[] | select(.id > 0) | .id]) as $occupied |

        # Predefined workspaces 1-10 plus dropdown (id -99) and magic (id -98)
        [
            (range(1;11) | {
                id: .,
                name: (. | tostring),
                label: (
                    if . <= 5 then "A\(.)"
                    elif . == 6 then "A6"
                    elif . <= 9 then "B\(.)"
                    elif . == 10 then "B0"
                    else (. | tostring)
                    end
                ),
                active: (. == $active),
                occupied: (. as $id | $occupied | any(. == $id)),
                visible: (. as $id | $visible | any(. == $id))
            }),
            {
                id: -99,
                name: "special:dropdown",
                label: "xD",
                active: (-99 == $active),
                occupied: (-99 as $id | $occupied | any(. == $id)),
                visible: (-99 as $id | $visible | any(. == $id))
            },
            {
                id: -98,
                name: "special:magic",
                label: "xM",
                active: (-98 == $active),
                occupied: (-98 as $id | $occupied | any(. == $id)),
                visible: (-98 as $id | $visible | any(. == $id))
            }
        ]
    '
}

# Output initial state
query_workspaces

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        workspace\>\>*|createworkspace\>\>*|destroyworkspace\>\>*|openwindow\>\>*|closewindow\>\>*|movewindow\>\>*|activewindow\>\>*)
            query_workspaces
            ;;
    esac
done
