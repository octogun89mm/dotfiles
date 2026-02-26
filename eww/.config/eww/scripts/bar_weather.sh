#!/usr/bin/env bash

# Weather wrapper for eww bar popup
# Calls the existing weather.py and extracts relevant fields

output=$(python3 ~/.config/waybar/scripts/weather.py 2>/dev/null)

if [[ -z "$output" ]]; then
    echo '{"text":"N/A","icon":"","class":"error"}'
    exit 0
fi

echo "$output" | jq -c '{text: .text, icon: (.alt // ""), class: (.class // "")}'
