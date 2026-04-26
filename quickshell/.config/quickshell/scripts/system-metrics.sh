#!/usr/bin/env bash

set -euo pipefail

EWW_BAR="$HOME/.dotfiles/eww/.config/eww/scripts/eww-bar"

trim() {
    printf '%s' "$1" | tr -d '\n'
}

cpu="$(trim "$("$EWW_BAR" cpu-usage 2>/dev/null || true)")"
cpu_temp="$(trim "$("$EWW_BAR" cpu-temp 2>/dev/null || true)")"
mem_used="$(trim "$("$EWW_BAR" memory-used 2>/dev/null || true)")"
mem_total="$(trim "$("$EWW_BAR" memory-total 2>/dev/null || true)")"
updates="$(trim "$("$EWW_BAR" updates 2>/dev/null || true)")"
load1="$(awk '{print $1}' /proc/loadavg 2>/dev/null || true)"
gpu_json="$("$EWW_BAR" gpu 2>/dev/null || true)"

if ! printf '%s' "${gpu_json:-'{}'}" | jq -e . >/dev/null 2>&1; then
    gpu_json='{}'
fi

jq -cn \
  --arg cpu "$cpu" \
  --arg cpu_temp "$cpu_temp" \
  --arg mem_used "$mem_used" \
  --arg mem_total "$mem_total" \
  --arg updates "$updates" \
  --arg load1 "$load1" \
  --argjson gpu "$gpu_json" \
  '{
    cpu: ($cpu | tonumber? // null),
    cpu_temp: (if ($cpu_temp | length) > 0 then $cpu_temp else null end),
    load1: ($load1 | tonumber? // null),
    gpu: ($gpu.usage // null),
    gpu_temp: ($gpu.temp // null),
    gpu_vram_used: ($gpu.vram_used // null),
    gpu_vram_total: ($gpu.vram_total // null),
    mem_used: $mem_used,
    mem_total: $mem_total,
    updates: ($updates | tonumber? // null)
  }'
