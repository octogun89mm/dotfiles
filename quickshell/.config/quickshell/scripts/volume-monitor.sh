#!/usr/bin/env bash

# Polls wpctl for volume/mute/sink state and outputs JSON on change

last=""
while true; do
  raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
  vol=$(echo "$raw" | grep -oP '[\d.]+' | head -1)
  vol_pct=$(awk "BEGIN{printf \"%d\", $vol * 100}")
  muted=false
  [[ "$raw" == *MUTED* ]] && muted=true

  sink=$(wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' | sed -n '/Sinks:/,/Sources:/p' | grep -oP '\*\s+\d+\.\s+\K.*(?=\s+\[vol)' | sed 's/[[:space:]]*$//')

  current="{\"volume\":$vol_pct,\"muted\":$muted,\"sink\":\"$sink\"}"
  if [[ "$current" != "$last" ]]; then
    echo "$current"
    last="$current"
  fi
  sleep 0.3
done
