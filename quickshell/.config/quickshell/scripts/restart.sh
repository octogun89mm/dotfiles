#!/usr/bin/env bash
# Thin shim kept for callers (theme-apply.sh, muscle memory).
# qs-switch.sh restart kills whichever config is active and relaunches it.
exec "$HOME/.config/quickshell/scripts/qs-switch.sh" restart
