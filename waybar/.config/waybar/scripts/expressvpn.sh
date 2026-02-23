#!/usr/bin/env bash

toggle() {
    status="$(expressvpnctl status 2>&1)"
    first_line="$(head -n1 <<< "$status")"

    if [[ "$first_line" =~ ^Connected ]]; then
        expressvpnctl disconnect &>/dev/null
    else
        expressvpnctl connect &>/dev/null
    fi
    pkill -RTMIN+9 waybar
}

status() {
    status="$(expressvpnctl status 2>&1)"
    first_line="$(head -n1 <<< "$status")"

    if [[ "$first_line" =~ ^Connected\ to\ (.+)$ ]]; then
        location="${BASH_REMATCH[1]}"

        protocol="$(grep '^Protocol in use:' <<< "$status" | sed 's/^Protocol in use: //' | tr -d '\n')"
        lock="$(grep '^Network Lock:' <<< "$status" | sed 's/^Network Lock: //' | tr -d '\n')"
        split="$(grep '^Split Tunnel:' <<< "$status" | sed 's/^Split Tunnel: //' | tr -d '\n')"

        jq --unbuffered --compact-output -n \
            --arg location "$location" \
            --arg protocol "$protocol" \
            --arg lock "$lock" \
            --arg split "$split" \
            '{
                text: "CONNECTED",
                alt: "󰒘",
                class: "vpn-connected",
                tooltip: (
                    [
                        "Location: " + $location,
                        "Protocol: " + $protocol,
                        "Network Lock: " + $lock,
                        "Split Tunnel: " + $split
                    ] | join("\n")
                )
            }'
    else
        jq --unbuffered --compact-output -n \
            '{
                text: "DISCONNECTED",
                alt: "󰒙",
                class: "vpn-disconnected",
                tooltip: "ExpressVPN is disconnected"
            }'
    fi
}

case "$1" in
    toggle) toggle ;;
    *) status ;;
esac
