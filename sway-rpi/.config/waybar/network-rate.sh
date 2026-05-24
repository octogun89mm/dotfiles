#!/usr/bin/env bash

set -euo pipefail

state_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-network-rate.state"

active_device() {
  nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null \
    | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }'
  return 0
}

fallback_device() {
  for path in /sys/class/net/*; do
    iface="${path##*/}"
    case "$iface" in
      lo|tailscale*|docker*|br-*|veth*) continue ;;
    esac

    if [[ -r "$path/operstate" ]] && [[ "$(cat "$path/operstate")" == "up" ]]; then
      printf '%s\n' "$iface"
      return
    fi
  done
}

iface="$(active_device || true)"
if [[ -z "$iface" ]]; then
  iface="$(fallback_device)"
fi

rx=0
tx=0
signal=0

if [[ -n "$iface" && -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
  rx="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
  tx="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
fi

if [[ -n "$iface" ]]; then
  signal="$(
    nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null \
      | awk -F: '$1 == "yes" { print $2; exit }'
  )" || true
fi
signal="${signal:-0}"

now="$(date +%s%N)"
prev_rx="$rx"
prev_tx="$tx"
prev_now="$now"

if [[ -r "$state_file" ]]; then
  read -r prev_rx prev_tx prev_now < "$state_file" || true
fi

printf '%s %s %s\n' "$rx" "$tx" "$now" > "$state_file"

elapsed_ns=$(( now - prev_now ))
if (( elapsed_ns <= 0 )); then
  elapsed_ns=1000000000
fi

rx_delta=$(( rx >= prev_rx ? rx - prev_rx : 0 ))
tx_delta=$(( tx >= prev_tx ? tx - prev_tx : 0 ))

down="$(awk -v b="$rx_delta" -v ns="$elapsed_ns" 'BEGIN { printf "%.2f", (b / 1000000) / (ns / 1000000000) }')"
up="$(awk -v b="$tx_delta" -v ns="$elapsed_ns" 'BEGIN { printf "%.2f", (b / 1000000) / (ns / 1000000000) }')"

printf 'NET ↓%s ↑%s %s%%\n' "$down" "$up" "$signal"
