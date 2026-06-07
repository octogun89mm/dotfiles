#!/usr/bin/env bash

set -euo pipefail

theme="${1:-}"
if [[ -z "$theme" ]]; then
  printf 'usage: %s <wallust-theme-or-colorscheme>\n' "${0##*/}" >&2
  exit 2
fi

home="${HOME:?}"
colorscheme="$home/.config/wallust/colorschemes/$theme.json"
mode="dark"

case "${theme,,}" in
  *light*|*day*|*dawn*|*white*|*latte*|fruitager*) mode="light" ;;
esac

if [[ -f "$colorscheme" ]]; then
  wallust cs "$theme"
else
  wallust theme "$theme"
fi

mkdir -p "$home/.cache"
printf '%s\n' "$theme" > "$home/.cache/wallust-current-theme"
printf '%s\n' "$mode" > "$home/.cache/wallust-current-mode"
printf '%s\n' "theme" > "$home/.cache/wallust-current-source"
printf '%s\n' "theme" > "$home/.cache/quickshell-theme-picker-mode"

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

if command -v dunstctl >/dev/null 2>&1; then
  dunstctl reload >/dev/null 2>&1 || true
fi

if command -v ghostty >/dev/null 2>&1; then
  ghostty +validate-config >/dev/null 2>&1 || true
fi

if [[ -x "$home/.config/quickshell/scripts/restart.sh" ]]; then
  setsid -f "$home/.config/quickshell/scripts/restart.sh" >/dev/null 2>&1 || true
fi
