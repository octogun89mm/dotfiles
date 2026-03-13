#!/usr/bin/env bash

set -euo pipefail

mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')

if (( ${#sinks[@]} < 2 )); then
    exit 0
fi

current_sink="$(pactl info | sed -n 's/^Default Sink: //p')"
next_sink="${sinks[0]}"

for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current_sink" ]]; then
        next_sink="${sinks[$(( (i + 1) % ${#sinks[@]} ))]}"
        break
    fi
done

pactl set-default-sink "$next_sink"

while read -r input_id _; do
    [[ -n "${input_id:-}" ]] || continue
    pactl move-sink-input "$input_id" "$next_sink"
done < <(pactl list short sink-inputs)

notify-send -a "Audio Output" -t 2000 "Sink switched" "$next_sink"
