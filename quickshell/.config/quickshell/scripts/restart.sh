#!/usr/bin/env bash

set -euo pipefail

quickshell kill || true
exec "$HOME/.config/quickshell/scripts/launch.sh"
