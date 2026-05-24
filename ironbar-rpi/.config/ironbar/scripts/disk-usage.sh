#!/usr/bin/env bash
set -euo pipefail

if ! line="$(df -BG -P / 2>/dev/null | awk 'NR==2 { gsub(/G/, "", $2); gsub(/G/, "", $3); gsub(/%/, "", $5); printf "%s|%s|%s\n", $2, $3, $5 }')"; then
  printf 'DISK --\n'
  exit 0
fi

if [ -z "$line" ]; then
  printf 'DISK --\n'
  exit 0
fi

IFS='|' read -r _total_g _used_g used_pct <<<"$line"

printf 'DISK %s%%\n' "$used_pct"
