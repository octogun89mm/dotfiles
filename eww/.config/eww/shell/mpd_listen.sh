#!/usr/bin/env bash

# MPD idle-based listener for eww deflisten
# Uses mpc idleloop (zero CPU when idle)

query_mpd() {
    local current state elapsed total progress artist title

    current=$(mpc -f '%artist%\t%title%' current 2>/dev/null)
    artist="${current%%	*}"
    title="${current#*	}"

    # If no tab separator, title equals artist (single field)
    [[ "$current" != *$'\t'* ]] && title="$artist" && artist=""

    state=$(mpc status 2>/dev/null | sed -n 's/^\[\(.*\)\].*/\1/p')
    state="${state:-stopped}"

    local times
    times=$(mpc status 2>/dev/null | sed -n 's/.*\([0-9]*:[0-9]*\)\/\([0-9]*:[0-9]*\).*/\1\t\2/p')
    elapsed="${times%%	*}"
    total="${times#*	}"
    elapsed="${elapsed:-0:00}"
    total="${total:-0:00}"

    # Calculate progress percentage
    local e_sec t_sec
    e_sec=$(echo "$elapsed" | awk -F: '{print ($1 * 60) + $2}')
    t_sec=$(echo "$total" | awk -F: '{print ($1 * 60) + $2}')
    if [[ "$t_sec" -gt 0 ]]; then
        progress=$(awk "BEGIN {printf \"%.0f\", ($e_sec / $t_sec) * 100}")
    else
        progress=0
    fi

    jq -cn \
        --arg state "$state" \
        --arg artist "$artist" \
        --arg title "$title" \
        --arg elapsed "$elapsed" \
        --arg total "$total" \
        --argjson progress "$progress" \
        '{state: $state, artist: $artist, title: $title, elapsed: $elapsed, total: $total, progress: $progress}'
}

# Output initial state
query_mpd

mpc idleloop player 2>/dev/null | while read -r _; do
    query_mpd
done
