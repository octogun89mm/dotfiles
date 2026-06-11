#!/usr/bin/env bash
#
# qs-ipc.sh — send an IPC call to whichever quickshell instance is running.
#
# `quickshell ipc call` only targets the default config (shell.qml), which
# fails when the square profile is active. Targeting by pid works for both.
#
# Usage: qs-ipc.sh <target> <function> [args...]

set -euo pipefail

pid="$(pgrep -ox quickshell)" || {
  echo "qs-ipc: no quickshell instance running" >&2
  exit 1
}

exec quickshell ipc --pid "$pid" call "$@"
