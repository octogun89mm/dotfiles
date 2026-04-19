#!/usr/bin/env bash
# Install (symlink) these dotfiles into $HOME using GNU Stow.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

STOW_TARGET="$HOME"
SKIP_DIRS=(assets)

if [[ -t 1 ]]; then
  C_BOLD=$'\e[1m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'
  C_RED=$'\e[31m'; C_RESET=$'\e[0m'
else
  C_BOLD= C_GREEN= C_YELLOW= C_RED= C_RESET=
fi

log()  { printf '%s→%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

detect_packages() {
  local dir pkg s skip
  for dir in */; do
    pkg="${dir%/}"
    skip=0
    for s in "${SKIP_DIRS[@]}"; do
      [[ "$pkg" == "$s" ]] && { skip=1; break; }
    done
    (( skip )) || printf '%s\n' "$pkg"
  done
}

usage() {
  cat <<EOF
${C_BOLD}Usage:${C_RESET} $(basename "$0") [options] [packages...]

Symlinks configs from ${DOTFILES_DIR} into ${STOW_TARGET} using GNU Stow.

${C_BOLD}Options:${C_RESET}
  -D, --unstow     Remove symlinks (uninstall).
  -R, --restow     Unstow then re-stow (refresh links).
  -n, --dry-run    Simulate — print actions without making changes.
  -h, --help       Show this help.

${C_BOLD}Packages:${C_RESET}
  If none given, all detected packages are used:
$(detect_packages | sed 's/^/    • /')

${C_BOLD}Examples:${C_RESET}
  $(basename "$0")              # install everything
  $(basename "$0") nvim zsh     # install specific packages
  $(basename "$0") -D           # uninstall everything
  $(basename "$0") -n nvim      # dry-run nvim only
EOF
}

ACTION="--stow"
DRY=()
PKGS=()

while (( $# > 0 )); do
  case "$1" in
    -D|--unstow)  ACTION="--delete";;
    -R|--restow)  ACTION="--restow";;
    -n|--dry-run) DRY=(-n);;
    -h|--help)    usage; exit 0;;
    --)           shift; PKGS+=("$@"); break;;
    -*)           die "Unknown flag: $1 (use -h for help)";;
    *)            PKGS+=("$1");;
  esac
  shift
done

command -v stow >/dev/null 2>&1 || die "GNU Stow not found — install with: yay -S stow"

if (( ${#PKGS[@]} == 0 )); then
  while IFS= read -r p; do PKGS+=("$p"); done < <(detect_packages)
fi
(( ${#PKGS[@]} > 0 )) || die "No packages to process."

stow_args=(-t "$STOW_TARGET" -d "$DOTFILES_DIR" -v "$ACTION")
(( ${#DRY[@]} )) && stow_args+=("${DRY[@]}")

log "${C_BOLD}${ACTION#--}${C_RESET} → ${STOW_TARGET}"
log "Packages: ${PKGS[*]}"
(( ${#DRY[@]} )) && warn "Dry run — no changes will be written."

stow "${stow_args[@]}" -- "${PKGS[@]}"

log "Done."
