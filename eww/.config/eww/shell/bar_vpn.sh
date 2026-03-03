#!/usr/bin/env bash

# ExpressVPN status for eww bar popup (poll-based)
# Outputs JSON {status, icon, location}

status="$(expressvpnctl status 2>&1)"
first_line="$(head -n1 <<< "$status")"

if [[ "$first_line" =~ ^Connected\ to\ (.+)$ ]]; then
    location="${BASH_REMATCH[1]}"
    jq -cn --arg loc "$location" '{status: "connected", icon: "󰒘", location: $loc}'
else
    echo '{"status":"disconnected","icon":"󰒙","location":""}'
fi
