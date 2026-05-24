#!/usr/bin/env bash
set -euo pipefail

speaker_mac="FC:58:FA:B2:15:DD"
bt_sink_prefix="bluez_output.FC_58_FA_B2_15_DD"
hdmi_sink_name="alsa_output.platform-107c706400.hdmi.hdmi-stereo"

sink_line() {
  local pattern="$1"
  pactl list short sinks 2>/dev/null | awk -v pat="$pattern" 'index($2, pat) == 1 { print; exit }'
}

move_inputs() {
  local target_sink="$1"
  pactl list short sink-inputs 2>/dev/null | awk '{ print $1 }' | while read -r input_id; do
    [ -n "$input_id" ] || continue
    pactl move-sink-input "$input_id" "$target_sink" >/dev/null 2>&1 || true
  done
}

status_line() {
  local bt_line default_sink bt_sink_id bt_sink_name bt_volume active_label

  if ! command -v pactl >/dev/null 2>&1; then
    printf 'BT --\n'
    return
  fi

  bt_line="$(sink_line "$bt_sink_prefix" || true)"
  default_sink="$(pactl info 2>/dev/null | awk -F': ' '/^Default Sink:/ { print $2; exit }' || true)"

  if [ -z "$bt_line" ]; then
    printf 'BT off\n'
    return
  fi

  bt_sink_id="$(printf '%s\n' "$bt_line" | awk '{ print $1 }')"
  bt_sink_name="$(printf '%s\n' "$bt_line" | awk '{ print $2 }')"
  bt_volume="$(pactl get-sink-volume "$bt_sink_id" 2>/dev/null | awk -F'/' '/Volume:/ { gsub(/[^0-9]/, "", $2); print $2; exit }')"
  bt_volume="${bt_volume:-0}"
  active_label=""

  if [ "${default_sink:-}" = "$bt_sink_name" ]; then
    active_label="*"
  fi

  printf 'BT%s %s%%\n' "$active_label" "$bt_volume"
}

toggle_speaker() {
  local bt_line hdmi_line bt_sink_name default_sink

  if ! command -v pactl >/dev/null 2>&1; then
    return
  fi

  bt_line="$(sink_line "$bt_sink_prefix" || true)"
  hdmi_line="$(pactl list short sinks 2>/dev/null | awk -v name="$hdmi_sink_name" '$2 == name { print; exit }' || true)"
  default_sink="$(pactl info 2>/dev/null | awk -F': ' '/^Default Sink:/ { print $2; exit }' || true)"

  if [ -z "$bt_line" ]; then
    if command -v bluetoothctl >/dev/null 2>&1; then
      bluetoothctl connect "$speaker_mac" >/dev/null 2>&1 || true
    fi
    return
  fi

  bt_sink_name="$(printf '%s\n' "$bt_line" | awk '{ print $2 }')"
  if [ "${default_sink:-}" = "$bt_sink_name" ]; then
    if [ -n "$hdmi_line" ]; then
      pactl set-default-sink "$hdmi_sink_name"
      move_inputs "$hdmi_sink_name"
    fi
  else
    pactl set-volume "$bt_sink_name" 10%
    pactl set-default-sink "$bt_sink_name"
    move_inputs "$bt_sink_name"
  fi
}

case "${1:-}" in
  toggle)
    toggle_speaker
    status_line
    ;;
  *)
    status_line
    while :; do
      if pactl subscribe 2>/dev/null | while IFS= read -r line; do
        case "$line" in
          *" on sink "*|*" on card "*|*" on server "*)
            status_line
            ;;
        esac
      done; then
        :
      fi
      sleep 1
    done
    ;;
esac
