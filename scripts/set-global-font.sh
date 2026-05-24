#!/usr/bin/env bash
# Install a larger no-ligature monospace set on Ubuntu and pick one with rofi.
#
# Usage:
#   set-global-font.sh --install      # install the curated font set, then pick
#   set-global-font.sh --pick         # browse installed monospace fonts in rofi
#   set-global-font.sh --apply NAME   # apply a specific family directly
#   set-global-font.sh --list         # list the monospace families we can see

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
FONTCONFIG_DIR="$HOME/.config/fontconfig/conf.d"
FONTCONFIG_FILE="$FONTCONFIG_DIR/50-monospace-default.conf"
GNOME_MONO_SIZE="${GNOME_MONO_SIZE:-11}"

BASE_PACKAGES=(
  fonts-anonymous-pro
  fonts-agave
  fonts-3270
  fonts-courier-prime
  fonts-fantasque-sans
  fonts-hack
  fonts-hermit
  fonts-inconsolata
  fonts-mononoki
  fonts-noto-mono
  fonts-proggy
  fonts-terminus
  fonts-cmu
  fonts-croscore
  fonts-dejavu-core
  fonts-dejavu-extra
  fonts-freefont-ttf
  fonts-liberation
  fonts-liberation2
  fonts-ubuntu
)

EXTRA_PACKAGES=(
  fonts-b612
  fonts-firacode
  fonts-freefont-otf
  fonts-go
  fonts-gnutypewriter
  fonts-hosny-thabit
  fonts-ibm-plex
  fonts-jetbrains-mono
  fonts-league-mono
  fonts-monoid
  fonts-monoid-halfloose
  fonts-monoid-halftight
  fonts-monoid-loose
  fonts-monoid-tight
  fonts-monofur
  fonts-naver-d2coding
  fonts-ricty-diminished
  fonts-spleen
  fonts-sixtyfour
  fonts-ubuntu-console
  fonts-amiga
  fonts-tlwg-mono-otf
  fonts-tlwg-mono-ttf
  fonts-tlwg-typewriter-otf
  fonts-tlwg-typewriter-ttf
  fonts-tlwg-typist-otf
  fonts-tlwg-typist-ttf
  fonts-tlwg-typo-otf
  fonts-tlwg-typo-ttf
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Pick a monospace font from the ones installed on the system, preview it in rofi,
and then apply it through fontconfig, GNOME monospace settings, and repo-local
dotfiles when available.

Options:
  --install        Install the curated font packages before picking.
  --pick           Open the rofi picker and apply the selection.
  --apply NAME     Apply a specific family without opening rofi.
  --list           Print the monospace families visible to fontconfig.
  -h, --help       Show this help.

Environment:
  DOTFILES_DIR     Override the repo root used to call scripts/set-font.sh.
  GNOME_MONO_SIZE  Font size used for gsettings and preview rows (default: 11).
EOF
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

xml_escape() {
  local s=$1
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//\"/&quot;}
  printf '%s' "$s"
}

list_mono_families() {
  fc-list ':spacing=100' family \
    | sed -E 's#^.*: ##; s#:style.*$##' \
    | tr ',' '\n' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | awk 'NF' \
    | grep -Ev 'Emoji|Fallback|Math|SignWrit' \
    | sort -fu
}

install_fonts() {
  need apt-get

  local -a sudo_cmd=()
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    need sudo
    sudo_cmd=(sudo)
  fi

  local -a packages=("${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}")
  printf 'Installing %d font packages...\n' "${#packages[@]}"
  "${sudo_cmd[@]}" apt-get update
  "${sudo_cmd[@]}" apt-get install -y --no-install-recommends -- "${packages[@]}"
  hot_reload
}

pick_family() {
  need rofi

  local -a families=()
  mapfile -t families < <(list_mono_families)
  (( ${#families[@]} > 0 )) || die "No monospace families found. Install fonts first."

  local choice
  choice="$(printf '%s\n' "${families[@]}" | rofi -dmenu -i -format s -p "Font")" || exit 1
  [[ -n "$choice" ]] || exit 1
  printf '%s\n' "$choice"
}

apply_family() {
  local family=$1 family_xml
  family_xml="$(xml_escape "$family")"

  mkdir -p "$FONTCONFIG_DIR"
  cat > "$FONTCONFIG_FILE" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>${family_xml}</family>
    </prefer>
  </alias>
  <match target="font">
    <edit name="fontfeatures" mode="append">
      <string>liga off</string>
      <string>clig off</string>
      <string>dlig off</string>
      <string>calt off</string>
    </edit>
  </match>
</fontconfig>
EOF

  fc-cache -f >/dev/null 2>&1 || true

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface monospace-font-name "${family} ${GNOME_MONO_SIZE}" >/dev/null 2>&1 || true
  fi

  if [[ -x "$DOTFILES_DIR/scripts/set-font.sh" ]]; then
    DOTFILES="$DOTFILES_DIR" "$DOTFILES_DIR/scripts/set-font.sh" "$family" >/dev/null 2>&1 || true
  fi

  hot_reload
  printf '%s\n' "$family"
}

hot_reload() {
  fc-cache -f >/dev/null 2>&1 || true

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi

  if command -v swaymsg >/dev/null 2>&1; then
    pkill -x waybar >/dev/null 2>&1 || true
    swaymsg reload >/dev/null 2>&1 || true
  elif command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet waybar.service 2>/dev/null; then
    systemctl --user restart waybar.service >/dev/null 2>&1 || true
  else
    pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
  fi

  if command -v makoctl >/dev/null 2>&1; then
    makoctl reload >/dev/null 2>&1 || true
  fi

  if pgrep -x dunst >/dev/null 2>&1; then
    pkill -x dunst >/dev/null 2>&1 || true
    if command -v dunst >/dev/null 2>&1; then
      setsid dunst >/dev/null 2>&1 &
    fi
  fi

  if pgrep -x eww >/dev/null 2>&1 && command -v eww >/dev/null 2>&1; then
    eww reload >/dev/null 2>&1 || true
  fi

  if pgrep -x quickshell >/dev/null 2>&1; then
    local qs_restart="$DOTFILES_DIR/rust-tools/target/release/quickshell-restart"
    local qs_launch="$HOME/.config/quickshell/scripts/launch.sh"
    if [[ -x "$qs_restart" ]]; then
      setsid "$qs_restart" >/dev/null 2>&1 &
    elif [[ -x "$qs_launch" ]]; then
      pkill -x quickshell >/dev/null 2>&1 || true
      setsid "$qs_launch" >/dev/null 2>&1 &
    fi
  fi
}

ACTION="pick"
TARGET=""
DO_INSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      DO_INSTALL=1
      shift
      ;;
    --pick)
      ACTION="pick"
      shift
      ;;
    --apply)
      ACTION="apply"
      TARGET="${2:-}"
      [[ -n "$TARGET" ]] || die "--apply needs a font family name"
      shift 2
      ;;
    --list)
      ACTION="list"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown argument: $1 (use --help)" ;;
  esac
done

if (( DO_INSTALL )); then
  install_fonts
fi

case "$ACTION" in
  list)
    list_mono_families
    ;;
  apply)
    [[ -n "$TARGET" ]] || die "--apply needs a font family name"
    apply_family "$TARGET"
    ;;
  pick)
    apply_family "$(pick_family)"
    ;;
  *)
    die "Internal error: unknown action '$ACTION'"
    ;;
esac
