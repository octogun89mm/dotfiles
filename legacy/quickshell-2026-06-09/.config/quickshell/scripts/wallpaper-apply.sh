#!/usr/bin/env bash

set -euo pipefail

wallpaper="${1:-}"
if [[ -z "$wallpaper" ]]; then
  printf 'usage: %s <wallpaper-image>\n' "${0##*/}" >&2
  exit 2
fi

if [[ ! -f "$wallpaper" ]]; then
  printf 'wallpaper not found: %s\n' "$wallpaper" >&2
  exit 1
fi

home="${HOME:?}"
hyprpaper_conf="$home/.config/hypr/hyprpaper.conf"
name="$(basename "$wallpaper")"

mkdir -p "$home/.cache" "$(dirname "$hyprpaper_conf")"

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 || true
  hyprctl hyprpaper wallpaper ",$wallpaper" >/dev/null 2>&1 || true
  hyprctl hyprpaper unload unused >/dev/null 2>&1 || true
fi

cat > "$hyprpaper_conf" <<EOF
splash = false

wallpaper {
    monitor =
    path = $wallpaper
}
EOF

wallust run "$wallpaper"

printf '%s\n' "$name" > "$home/.cache/wallust-current-theme"
printf '%s\n' "$wallpaper" > "$home/.cache/wallust-current-wallpaper"
printf '%s\n' "wallpaper" > "$home/.cache/wallust-current-source"
printf '%s\n' "wallpaper" > "$home/.cache/quickshell-theme-picker-mode"

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

if command -v dunstctl >/dev/null 2>&1; then
  dunstctl reload >/dev/null 2>&1 || true
fi

if command -v ghostty >/dev/null 2>&1; then
  ghostty +validate-config >/dev/null 2>&1 || true
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send -a "Wallpaper" -u low -t 2500 "Wallpaper" "Set to $name" >/dev/null 2>&1 || true
fi

if [[ -x "$home/.config/quickshell/scripts/restart.sh" ]]; then
  setsid -f "$home/.config/quickshell/scripts/restart.sh" >/dev/null 2>&1 || true
fi
