#!/usr/bin/env bash
#
# qs-switch.sh — switch between quickshell configs (classic <-> square).
#
# Usage: qs-switch.sh [classic|square|toggle|restart|status]
#   classic  switch to the default config (~/.config/quickshell/shell.qml)
#   square   switch to the square config  (~/.config/quickshell/square/)
#   toggle   flip between the two (default action)
#   restart  kill and relaunch the currently active config
#   status   print the active config name
#
# The active config is persisted so launch.sh (hyprland exec-once) honours it.

set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
state_file="$state_dir/active-config"
launch="$HOME/.config/quickshell/scripts/launch.sh"

current() {
  local val="classic"
  [[ -r "$state_file" ]] && val="$(<"$state_file")"
  case "$val" in classic|square) ;; *) val="classic" ;; esac
  printf '%s' "$val"
}

action="${1:-toggle}"
active="$(current)"

case "$action" in
  status)
    echo "$active"
    exit 0
    ;;
  toggle)
    [[ "$active" == "classic" ]] && target="square" || target="classic"
    ;;
  restart)
    target="$active"
    ;;
  classic|square)
    target="$action"
    ;;
  *)
    echo "usage: ${0##*/} [classic|square|toggle|restart|status]" >&2
    exit 2
    ;;
esac

mkdir -p "$state_dir"
printf '%s\n' "$target" > "$state_file"

# Kill every running quickshell instance and wait for them to exit.
mapfile -t pids < <(pgrep -x quickshell || true)
if ((${#pids[@]})); then
  kill "${pids[@]}" 2>/dev/null || true
  for _ in {1..50}; do
    pgrep -x quickshell >/dev/null || break
    sleep 0.1
  done
  pkill -9 -x quickshell 2>/dev/null || true
fi

setsid -f "$launch" >/dev/null 2>&1
echo "quickshell: $target"
