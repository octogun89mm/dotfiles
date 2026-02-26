#!/usr/bin/env bash

# Hyprland IPC listener for active window title
# Outputs JSON {class, title} for eww deflisten

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

query_active() {
    local info class title
    info=$(hyprctl activewindow -j 2>/dev/null)
    if [[ $? -ne 0 ]] || [[ -z "$info" ]] || [[ "$info" == "null" ]]; then
        echo '{"class":"","title":""}'
        return
    fi
    echo "$info" | jq -c '{class: (.class // ""), title: (.title // "")}'
}

# Output initial state
query_active

socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    case "$line" in
        activewindow\>\>*|closewindow\>\>*|movewindow\>\>*)
            query_active
            ;;
    esac
done
