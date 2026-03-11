#!/usr/bin/env bash

sinks_section() {
  wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' | sed -n '/Sinks:/,/Sources:/p'
}

case "$1" in
  set)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$(awk "BEGIN{printf \"%.2f\", $2/100}")"
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
  switch-sink)
    mapfile -t sinks < <(sinks_section | grep -oP '\d+(?=\.\s)')
    current=$(sinks_section | grep -oP '\*\s+\K\d+(?=\.)')
    for i in "${!sinks[@]}"; do
      if [[ "${sinks[$i]}" == "$current" ]]; then
        next=$(( (i + 1) % ${#sinks[@]} ))
        wpctl set-default "${sinks[$next]}"
        break
      fi
    done
    ;;
esac
