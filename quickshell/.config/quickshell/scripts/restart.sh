#!/usr/bin/env bash

set -euo pipefail

quickshell kill || true

for _ in $(seq 1 50); do
  if ! quickshell list | grep -q .; then
    break
  fi
  sleep 0.1
done

exec "$HOME/.config/quickshell/scripts/launch.sh"
