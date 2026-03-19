#!/bin/bash

set -euo pipefail

TODO_CMD="${TODO_CMD:-$HOME/.local/bin/todo}"
TODO_CONFIG="${TODO_CONFIG:-$HOME/.config/todoman/config.py}"
THEME="$HOME/.config/rofi/themes/todo.rasi"

todo_json() {
    "$TODO_CMD" --config "$TODO_CONFIG" --porcelain list 2>/dev/null || echo "[]"
}

add_task() {
    local task
    task=$(rofi -dmenu -p "New task" -theme "$THEME" -lines 0 || true)
    [[ -z "$task" ]] && return 0
    local priority
    priority=$(choose_priority "Priority") || return 0
    "$TODO_CMD" --config "$TODO_CONFIG" new --list personal --priority "$priority" "$task" >/dev/null 2>&1
}

mark_done() {
    local task_id=$1
    "$TODO_CMD" --config "$TODO_CONFIG" done "$task_id" >/dev/null 2>&1
}

remove_task() {
    local task_id=$1
    "$TODO_CMD" --config "$TODO_CONFIG" delete --yes "$task_id" >/dev/null 2>&1
}

set_priority() {
    local task_id=$1
    local priority
    priority=$(choose_priority "Set priority") || return 0
    "$TODO_CMD" --config "$TODO_CONFIG" edit --priority "$priority" "$task_id" >/dev/null 2>&1
}

choose_priority() {
    local prompt=${1:-Priority}
    local selected

    selected=$(printf "None\nLow\nMedium\nHigh" | rofi -dmenu -p "$prompt" -theme "$THEME" -i || true)
    [[ -z "$selected" ]] && return 1

    case "$selected" in
        "None") printf '0\n' ;;
        "Low") printf '7\n' ;;
        "Medium") printf '5\n' ;;
        "High") printf '3\n' ;;
        *) return 1 ;;
    esac
}

build_task_entry() {
    local summary due priority
    summary=$(jq -r '.summary' <<<"$1")
    due=$(jq -r '.due // empty' <<<"$1")
    priority=$(jq -r '.priority // empty' <<<"$1")

    local entry="[ ] $summary"

    if [[ -n "$due" ]]; then
        entry+=" (due: $due)"
    fi

    case "$priority" in
        1|2|3) entry+=" !!!" ;;
        4|5) entry+=" !!" ;;
        6|7) entry+=" !" ;;
    esac

    printf '%s\n' "$entry"
}

main_menu() {
    while true; do
        local json entries chosen index task_index task_id action
        json=$(todo_json)

        entries=""
        entries+="+ Add New Task\n"

        while IFS= read -r task; do
            entries+="$(build_task_entry "$task")\n"
        done < <(jq -c '.[]' <<<"$json")

        chosen=$(printf "%b" "$entries" | head -c -1 | rofi -dmenu -p "Todo" -theme "$THEME" -i -format 'i s' -selected-row 1 || true)
        [[ -z "$chosen" ]] && exit 0

        index="${chosen%% *}"

        if [[ "$index" == "0" ]]; then
            add_task
            continue
        fi

        task_index=$((index - 1))
        task_id=$(jq -r ".[$task_index].id" <<<"$json")
        [[ -z "$task_id" || "$task_id" == "null" ]] && continue

        action=$(printf "Mark done\nSet priority\nDelete task" | rofi -dmenu -p "Action" -theme "$THEME" -i || true)
        [[ -z "$action" ]] && continue

        case "$action" in
            "Mark done") mark_done "$task_id" ;;
            "Set priority") set_priority "$task_id" ;;
            "Delete task") remove_task "$task_id" ;;
        esac

        continue
    done
}

main_menu
