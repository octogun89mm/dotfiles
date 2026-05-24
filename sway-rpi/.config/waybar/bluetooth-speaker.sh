#!/usr/bin/env bash
set -euo pipefail

speaker_mac="FC:58:FA:B2:15:DD"
speaker_name="RC215PBT"
bt_sink_prefix="bluez_output.FC_58_FA_B2_15_DD"
hdmi_sink_name="alsa_output.platform-107c706400.hdmi.hdmi-stereo"
waybar_signal=8
script_path="$(readlink -f "${BASH_SOURCE[0]}")"

signal_waybar() {
  pkill -RTMIN+"$waybar_signal" -x waybar 2>/dev/null || true
}

ensure_watcher() {
  if pgrep -f -- "$script_path --watch" >/dev/null 2>&1; then
    return
  fi
  nohup "$script_path" --watch >/dev/null 2>&1 &
}

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

case "${1:-}" in
  --watch)
    trap 'exit 0' INT TERM
    while :; do
      pactl subscribe 2>/dev/null | while IFS= read -r line; do
        case "$line" in
          *" on sink "*|*" on card "*|*" on server "*)
            signal_waybar
            ;;
        esac
      done
      sleep 1
    done
    ;;
esac

ensure_watcher

bt_line="$(sink_line "$bt_sink_prefix" || true)"
hdmi_line="$(pactl list short sinks 2>/dev/null | awk -v name="$hdmi_sink_name" '$2 == name { print; exit }' || true)"
default_sink="$(pactl info 2>/dev/null | awk -F': ' '/^Default Sink:/ { print $2; exit }')"

if [ -z "$bt_line" ]; then
  if [ "${1:-}" = "toggle" ]; then
    bluetoothctl connect "$speaker_mac" >/dev/null 2>&1 || true
  fi
  printf '{"text":"BT off","tooltip":"%s\\nBluetooth sink is not available","class":"disconnected","percentage":0}\n' "$speaker_name"
  exit 0
fi

bt_sink_id="$(printf '%s\n' "$bt_line" | awk '{ print $1 }')"
bt_sink_name="$(printf '%s\n' "$bt_line" | awk '{ print $2 }')"
bt_sink_state="$(printf '%s\n' "$bt_line" | awk '{ print $NF }')"
bt_volume="$(pactl get-sink-volume "$bt_sink_id" 2>/dev/null | awk -F'/' '/Volume:/ { gsub(/[^0-9]/, "", $2); print $2; exit }')"
bt_volume="${bt_volume:-0}"
active_output=false
if [ "${default_sink:-}" = "$bt_sink_name" ]; then
  active_output=true
fi

if [ "${1:-}" = "toggle" ]; then
  if [ "$active_output" = true ]; then
    if [ -n "$hdmi_line" ]; then
      pactl set-default-sink "$hdmi_sink_name"
      move_inputs "$hdmi_sink_name"
    fi
  else
    pactl set-volume "$bt_sink_name" 10%
    pactl set-default-sink "$bt_sink_name"
    move_inputs "$bt_sink_name"
  fi
fi

state_class="connected"
next_action="switch to Bluetooth"
if [ "$active_output" = true ]; then
  state_class="active"
  next_action="switch to HDMI"
fi

printf '{"text":"BT %s%%","tooltip":"Speaker: %s\\nSink: %s\\nState: %s\\nVolume: %s%%\\nClick to %s","class":"%s","percentage":%s}\n' \
  "$bt_volume" "$speaker_name" "$bt_sink_name" "$bt_sink_state" "$bt_volume" "$next_action" "$state_class" "$bt_volume"
