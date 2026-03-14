#!/usr/bin/env bash

set -euo pipefail

selection=$(
    printf '%s\n' \
        "App launcher" \
        "Terminal" \
        "Dropdown terminal" \
        "Ranger" \
        "Neovim" \
        "Emacs" \
        "Firefox" \
        "Brave" \
        "Newsboat" \
        "Music player" |
    rofi -dmenu -i -p "Apps" -no-custom
)

[ -z "$selection" ] && exit 0

case "$selection" in
    "App launcher")
        exec rofi -show drun
        ;;
    "Terminal")
        exec foot
        ;;
    "Dropdown terminal")
        exec foot --app-id foot-scratchpad -o colors-dark.alpha=0.9
        ;;
    "Ranger")
        exec foot -e ranger
        ;;
    "Neovim")
        exec foot --app-id nvim -e nvim
        ;;
    "Emacs")
        exec emacsclient -c
        ;;
    "Firefox")
        exec firefox --new-window
        ;;
    "Brave")
        exec brave --new-window
        ;;
    "Newsboat")
        exec foot --app-id newsboat -e newsboat
        ;;
    "Music player")
        exec foot -e rmpc
        ;;
esac
