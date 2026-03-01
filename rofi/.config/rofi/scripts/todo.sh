#!/bin/bash

TODO_FILE="$HOME/Notes/todo.md"
THEME="$HOME/.config/rofi/themes/todo.rasi"

# Ensure the todo file exists
[[ -f "$TODO_FILE" ]] || touch "$TODO_FILE"

add_task() {
    local task
    task=$(rofi -dmenu -p "New task" -theme "$THEME" -lines 0)
    [[ -n "$task" ]] && echo "- [ ] $task" >> "$TODO_FILE"
}

toggle_task() {
    local line_num=$1
    if sed -n "${line_num}p" "$TODO_FILE" | grep -q '\- \[x\]'; then
        sed -i "${line_num}s/- \[x\]/- [ ]/" "$TODO_FILE"
    else
        sed -i "${line_num}s/- \[ \]/- [x]/" "$TODO_FILE"
    fi
}

remove_task() {
    local line_num=$1
    sed -i "${line_num}d" "$TODO_FILE"
}

main_menu() {
    while true; do
        # Build menu entries
        local entries=""
        entries+="> Launch Journal Chat\n"
        entries+="+ Add New Task\n"

        local i=1
        while IFS= read -r line; do
            if echo "$line" | grep -q '\- \[x\]'; then
                local text="${line#- \[x\] }"
                entries+="[x] $text\n"
            elif echo "$line" | grep -q '\- \[ \]'; then
                local text="${line#- \[ \] }"
                entries+="[ ] $text\n"
            fi
            ((i++))
        done < "$TODO_FILE"

        local chosen
        chosen=$(printf "%b" "$entries" | head -c -1 | rofi -dmenu -p "Todo" -theme "$THEME" -i -format 'i s' -selected-row 2)

        [[ -z "$chosen" ]] && exit 0

        local index="${chosen%% *}"
        local selected="${chosen#* }"

        # Journal chat (index 0)
        if [[ "$index" == "0" ]]; then
            foot --app-id journal -e zsh -ic journal &
            exit 0
        fi

        # Add new task (index 1)
        if [[ "$index" == "1" ]]; then
            add_task
            continue
        fi

        # Task selected — show action submenu
        local line_num=$((index - 1))  # offset by the 2 header entries
        local action
        action=$(printf "Toggle check\nRemove task" | rofi -dmenu -p "Action" -theme "$THEME" -i)

        case "$action" in
            "Toggle check") toggle_task "$line_num" ;;
            "Remove task") remove_task "$line_num" ;;
        esac
    done
}

main_menu
