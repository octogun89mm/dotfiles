#!/usr/bin/env bash
# Swap the monospace font family across dotfiles in one shot.
#
# Usage:
#   set-font.sh "Iosevka"                         # swap from tracked previous font
#   set-font.sh --from "Old Font" "New Font"      # explicit source family
#   set-font.sh --list                            # show files that get rewritten
#   set-font.sh --current                         # print tracked or detected font
#
# Reads both "Spaced Family" and collapsed "SpacedFamily" forms (legacy dunst/rofi),
# but always writes the spaced form — pango and rofi accept it.
# State file tracks the last family so repeated swaps work without re-specifying.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
STATE_FILE="$DOTFILES/scripts/.current-font"

FILES=(
  "$DOTFILES/hyprland/.config/hypr/hyprland.conf"
  "$DOTFILES/dunst/.config/dunst/dunstrc"
  "$DOTFILES/rofi/.config/rofi/themes/dmenu.rasi"
  "$DOTFILES/rofi/.config/rofi/themes/dmenu-vertical.rasi"
  "$DOTFILES/rofi/.config/rofi/themes/juju-default.rasi"
  "$DOTFILES/rofi/.config/rofi/themes/todo.rasi"
  "$DOTFILES/rofi/.config/rofi/themes/wallpaper.rasi"
  "$DOTFILES/eww/.config/eww/eww.scss"
  "$DOTFILES/eww/.config/eww/bar.scss"
  "$DOTFILES/waybar/.config/waybar/style-hyprland-top.css"
  "$DOTFILES/waybar/.config/waybar/style-hyprland-secondary.css"
  "$DOTFILES/sway/.config/sway/config"
  # Configs outside the dotfiles repo (optional — skipped silently if absent)
  "$HOME/.config/foot/foot.ini"
)

# QML files under quickshell — collected dynamically
mapfile -t QML_FILES < <(grep -rl "font.family" "$DOTFILES/quickshell/.config/quickshell" 2>/dev/null || true)
FILES+=("${QML_FILES[@]}")

detect_font() {
  local file line detected=""

  for file in "${FILES[@]}"; do
    [[ -f "$file" ]] || continue
    line="$(grep -m1 -E 'font-family:|font\.family:|font = |font pango:|font=' "$file" 2>/dev/null || true)"
    [[ -z "$line" ]] && continue

    detected="$(
      printf '%s\n' "$line" | sed -E \
        -e 's/.*font-family:[[:space:]]*"([^"]+)".*/\1/' \
        -e "s/.*font\\.family:[[:space:]]*\"([^\"]+)\".*/\\1/" \
        -e 's/.*font = "([^"]+)".*/\1/' \
        -e 's/.*font pango:([^[:digit:]]+).*/\1/' \
        -e 's/.*font=([^:]+).*/\1/' \
        -e 's/[[:space:]]+[0-9.]+$//' \
        -e 's/[[:space:]]+$//'
    )"

    [[ -n "$detected" ]] && [[ "$detected" != "$line" ]] && {
      printf '%s\n' "$detected"
      return 0
    }
  done

  return 1
}

current_font() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
    return 0
  fi

  detect_font || {
    echo "Unable to detect current font; pass --from explicitly." >&2
    return 1
  }
}

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

FROM=""
TO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --list) printf '%s\n' "${FILES[@]}"; exit 0 ;;
    --current) current_font; exit 0 ;;
    -h|--help) usage 0 ;;
    *) TO="$1"; shift ;;
  esac
done

[[ -z "$TO" ]] && usage 1
[[ -z "$FROM" ]] && FROM="$(current_font)"

FROM_COLLAPSED="${FROM// /}"

# Escape sed metacharacters for LHS/RHS (| is the delimiter, so it must be escaped)
sed_escape() { printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'; }

F1="$(sed_escape "$FROM")"
F2="$(sed_escape "$FROM_COLLAPSED")"
T1="$(sed_escape "$TO")"

echo "Swapping: '$FROM' → '$TO'"
changed=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || continue
  # Only rewrite the collapsed form if it differs from the spaced form;
  # otherwise a no-space family (e.g. "Iosevka") would match inside words.
  if [[ "$F1" != "$F2" ]] && grep -q "$F2" "$f"; then
    sed -i -e "s|${F2}|${T1}|g" "$f"
  fi
  if grep -q "$F1" "$f"; then
    sed -i -e "s|${F1}|${T1}|g" "$f"
    echo "  · $f"
    changed=$((changed + 1))
  fi
done

printf '%s\n' "$TO" > "$STATE_FILE"
echo "Done. $changed file(s) updated. State: $STATE_FILE"
echo
echo "Reload hints:"
echo "  hyprctl reload"
echo "  pkill -SIGUSR2 waybar   # or systemctl --user restart waybar"
echo "  makoctl reload 2>/dev/null; pkill dunst; dunst &  # dunst"
echo "  # quickshell: restart the shell process"
