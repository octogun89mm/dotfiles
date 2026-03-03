#!/usr/bin/env bash

set -euo pipefail

workspace_id=7
max_attempts=120
sleep_interval=0.25

get_client_json() {
    hyprctl clients -j
}

get_window() {
    local json="$1"
    local matcher="$2"

    jq -cer --arg matcher "$matcher" --argjson workspace_id "$workspace_id" '
        map(select(
            .workspace.id == $workspace_id and
            (.class == $matcher or .initialClass == $matcher)
        )) | first
    ' <<<"$json"
}

same_group() {
    local first="$1"
    local second="$2"
    local first_address="$3"
    local second_address="$4"

    jq -e \
        --arg first_address "$first_address" \
        --arg second_address "$second_address" '
        (.grouped | index($first_address)) != null and
        (.grouped | index($second_address)) != null
    ' <<<"$first" >/dev/null &&
    jq -e \
        --arg first_address "$first_address" \
        --arg second_address "$second_address" '
        (.grouped | index($first_address)) != null and
        (.grouped | index($second_address)) != null
    ' <<<"$second" >/dev/null
}

direction_to_anchor() {
    local anchor_x="$1"
    local anchor_y="$2"
    local target_x="$3"
    local target_y="$4"

    local dx=$((target_x - anchor_x))
    local dy=$((target_y - anchor_y))

    if (( ${dx#-} >= ${dy#-} )); then
        if (( target_x > anchor_x )); then
            printf 'l\n'
        else
            printf 'r\n'
        fi
    else
        if (( target_y > anchor_y )); then
            printf 'u\n'
        else
            printf 'd\n'
        fi
    fi
}

original_workspace="$(hyprctl activeworkspace -j | jq -r '.name // empty')"

telegram_json=''
vesktop_json=''

for _ in $(seq 1 "$max_attempts"); do
    clients_json="$(get_client_json)"

    telegram_json="$(get_window "$clients_json" 'org.telegram.desktop' || true)"
    vesktop_json="$(get_window "$clients_json" 'vesktop' || true)"

    if [[ -n "$telegram_json" && -n "$vesktop_json" ]]; then
        break
    fi

    sleep "$sleep_interval"
done

if [[ -z "$telegram_json" || -z "$vesktop_json" ]]; then
    exit 0
fi

telegram_address="$(jq -r '.address' <<<"$telegram_json")"
vesktop_address="$(jq -r '.address' <<<"$vesktop_json")"

if same_group "$telegram_json" "$vesktop_json" "$telegram_address" "$vesktop_address"; then
    exit 0
fi

telegram_x="$(jq -r '.at[0]' <<<"$telegram_json")"
telegram_y="$(jq -r '.at[1]' <<<"$telegram_json")"
vesktop_x="$(jq -r '.at[0]' <<<"$vesktop_json")"
vesktop_y="$(jq -r '.at[1]' <<<"$vesktop_json")"

direction="$(direction_to_anchor "$telegram_x" "$telegram_y" "$vesktop_x" "$vesktop_y")"

hyprctl dispatch workspace "$workspace_id" >/dev/null
hyprctl dispatch focuswindow "address:${telegram_address}" >/dev/null
hyprctl dispatch togglegroup >/dev/null
hyprctl dispatch focuswindow "address:${vesktop_address}" >/dev/null
hyprctl dispatch moveintogroup "$direction" >/dev/null

if [[ -n "$original_workspace" && "$original_workspace" != "$workspace_id" ]]; then
    hyprctl dispatch workspace "$original_workspace" >/dev/null
fi
