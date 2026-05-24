#!/usr/bin/env bash
set -euo pipefail

line="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"

if [ -z "$line" ]; then
  printf 'VOL --\n'
  exit 0
fi

volume="$(awk '{ printf "%d", ($2 * 100) + 0.5 }' <<<"$line")"

case "$line" in
  *MUTED*)
    printf 'muted\n'
    ;;
  *)
    printf 'VOL %s%%\n' "$volume"
    ;;
esac
