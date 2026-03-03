#!/usr/bin/env bash
# Wrapper script for EWW defpoll to read state files
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$(dirname "$SHELL_DIR")/scripts/state"
VAR_NAME="$1"
DEFAULT="$2"

if [[ -z "$VAR_NAME" ]]; then
    echo "${DEFAULT:-}"
    exit 0
fi

STATE_FILE="$STATE_DIR/${VAR_NAME}.state"

if [[ -f "$STATE_FILE" ]] && [[ -s "$STATE_FILE" ]]; then
    head -n 1 "$STATE_FILE"
else
    echo "${DEFAULT:-}"
fi
