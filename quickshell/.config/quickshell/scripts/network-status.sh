#!/usr/bin/env bash

set -euo pipefail

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

printf '{"iface":"%s","rx":%s,"tx":%s,"signal":%s}\n' \
  "$iface" "${rx:-0}" "${tx:-0}" "${signal:-0}"
