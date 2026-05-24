#!/usr/bin/env bash
set -euo pipefail

active_device() {
  nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null \
    | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }'
  return 0
}

fallback_device() {
  local path iface

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

sample() {
  local iface rx tx signal

  iface="$(active_device || true)"
  if [[ -z "$iface" ]]; then
    iface="$(fallback_device || true)"
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
  iface="${iface:-none}"
  signal="${signal:-0}"

  printf '%s %s %s %s\n' "$iface" "$rx" "$tx" "$signal"
}

read -r prev_iface prev_rx prev_tx prev_signal < <(sample)
sleep 1

while :; do
  read -r iface rx tx signal < <(sample)

  if [[ "$iface" != "$prev_iface" ]]; then
    prev_rx="$rx"
    prev_tx="$tx"
  fi

  rx_delta=$(( rx >= prev_rx ? rx - prev_rx : 0 ))
  tx_delta=$(( tx >= prev_tx ? tx - prev_tx : 0 ))
  down="$(awk -v b="$rx_delta" 'BEGIN { printf "%.2f", b / 1000000 }')"
  up="$(awk -v b="$tx_delta" 'BEGIN { printf "%.2f", b / 1000000 }')"

  printf 'NET v%s ^%s %s%%\n' "$down" "$up" "$signal"

  prev_iface="$iface"
  prev_rx="$rx"
  prev_tx="$tx"
  prev_signal="$signal"
  sleep 1
done
