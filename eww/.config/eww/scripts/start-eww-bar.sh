#!/usr/bin/env bash
#
# Start EWW bar windows (daemonless listener model)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Start eww daemon if needed and open windows
cd "$CONFIG_DIR"
eww daemon >/dev/null 2>&1 || true
eww open bar-primary
eww open bar-secondary
eww open bar-popup-0
eww open bar-popup-1
eww open bar-calendar-0
eww open bar-calendar-1
