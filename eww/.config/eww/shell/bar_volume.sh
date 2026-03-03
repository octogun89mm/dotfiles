#!/usr/bin/env bash

# PulseAudio/PipeWire volume listener for eww
# Outputs JSON {volume, muted, icon}

get_volume() {
    local vol muted icon default_sink sink_info

    default_sink=$(pactl get-default-sink)
    sink_info=$(pactl list sinks short | grep "$default_sink")

    vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
    muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP '(yes|no)')

    if [[ "$muted" == "yes" ]]; then
        icon="󰖁"
    elif [[ "$vol" -ge 66 ]]; then
        icon="󰕾"
    elif [[ "$vol" -ge 33 ]]; then
        icon="󰖀"
    else
        icon="󰕿"
    fi

    jq -cn --argjson vol "${vol:-0}" --arg muted "$muted" --arg icon "$icon" \
        '{volume: $vol, muted: ($muted == "yes"), icon: $icon}'
}

# Output initial state
get_volume

pactl subscribe 2>/dev/null | while read -r line; do
    case "$line" in
        *"sink"*|*"server"*)
            get_volume
            ;;
    esac
done
