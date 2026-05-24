#!/usr/bin/env bash

set -euo pipefail

if ! line="$(df -BG -P / 2>/dev/null | awk 'NR==2 { gsub(/G/, "", $2); gsub(/G/, "", $3); gsub(/%/, "", $5); printf "%s|%s|%s\n", $2, $3, $5 }')"; then
  printf '{"text":"DISK --","tooltip":"Failed to read disk usage","class":"critical","percentage":0}\n'
  exit 0
fi

if [ -z "$line" ]; then
  printf '{"text":"DISK --","tooltip":"Failed to read disk usage","class":"critical","percentage":0}\n'
  exit 0
fi

IFS='|' read -r total_g used_g used_pct <<<"$line"

state="normal"
if [ "$used_pct" -ge 90 ]; then
  state="critical"
elif [ "$used_pct" -ge 80 ]; then
  state="warning"
fi

free_g=$(( total_g - used_g ))

printf '{"text":"DISK %s%%","tooltip":"ROOT: %sG used / %sG total\\nFree: %sG","class":"%s","percentage":%s}\n' \
  "$used_pct" "$used_g" "$total_g" "$free_g" "$state" "$used_pct"
