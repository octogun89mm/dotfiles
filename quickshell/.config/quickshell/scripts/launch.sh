#!/usr/bin/env bash

set -euo pipefail

# Qt 6 may try to register the same portal app connection twice for this
# layer-shell process. It is harmless, but it pollutes Quickshell logs.
if [[ -n "${QT_LOGGING_RULES:-}" ]]; then
  export QT_LOGGING_RULES="${QT_LOGGING_RULES};qt.qpa.services.warning=false"
else
  export QT_LOGGING_RULES="qt.qpa.services.warning=false"
fi

# qs-switch.sh persists which config (classic|square) should be running.
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/active-config"
active="classic"
[[ -r "$state_file" ]] && active="$(<"$state_file")"

# NOTE: a root-level shell.qml disables named configs (-c), so use -p.
if [[ "$active" == "square" ]]; then
  exec quickshell -p "$HOME/.config/quickshell/square" --no-duplicate
fi
exec quickshell --no-duplicate
