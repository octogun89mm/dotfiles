#!/usr/bin/env bash

set -euo pipefail

config_path=$(readlink -f "$HOME/.config/quickshell/shell.qml")

pids=$(quickshell list 2>/dev/null | awk -v cfg="$config_path" '
  /^Instance/ { pid = ""; match_cfg = 0 }
  /Process ID:/ { pid = $NF }
  /Config path:/ && $NF == cfg { match_cfg = 1 }
  match_cfg && pid { print pid; pid = ""; match_cfg = 0 }
')

if [[ -n "$pids" ]]; then
  kill $pids 2>/dev/null || true
  for _ in $(seq 1 50); do
    alive=0
    for pid in $pids; do
      if kill -0 "$pid" 2>/dev/null; then alive=1; break; fi
    done
    (( alive == 0 )) && break
    sleep 0.1
  done
fi

exec "$HOME/.config/quickshell/scripts/launch.sh"
