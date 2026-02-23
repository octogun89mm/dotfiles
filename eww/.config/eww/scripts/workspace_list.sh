#!/usr/bin/env bash

# Hyprland IPC listener for workspace list
# Outputs JSON array for eww deflisten

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

query_workspaces() {
    local workspaces clients active_id

    workspaces=$(hyprctl workspaces -j)
    clients=$(hyprctl clients -j)
    active_id=$(hyprctl activeworkspace -j | jq '.id')

    echo "$workspaces" | jq -c --argjson clients "$clients" --argjson active "$active_id" '
        [.[] | select(.id > 0) | . as $ws | {
            id: .id,
            name: .name,
            focused: (.id == $active),
            window_count: (.windows),
            clients: [$clients[] | select(.workspace.id == $ws.id) | {title: .title, class: .class}]
        }] | sort_by(.id)
    '
}

# Output initial state
query_workspaces

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        workspace\>\>*|openwindow\>\>*|closewindow\>\>*|movewindow\>\>*|activewindow\>\>*|destroyworkspace\>\>*|createworkspace\>\>*)
            query_workspaces
            ;;
    esac
done
