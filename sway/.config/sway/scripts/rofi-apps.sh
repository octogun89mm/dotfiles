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
        "Helium" \
        "Zen" \
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
        exec ghostty
        ;;
    "Dropdown terminal")
        exec ghostty --class=scratchpad --background-opacity=0.9 -e zsh
        ;;
    "Ranger")
        exec ghostty -e ranger
        ;;
    "Neovim")
        exec ghostty --class=nvim -e nvim
        ;;
    "Emacs")
        exec emacsclient -c
        ;;
    "Helium")
        exec helium-browser
        ;;
    "Zen")
        exec zen-browser --new-window
        ;;
    "Newsboat")
        exec ghostty --class=newsboat -e newsboat
        ;;
    "Music player")
        exec ghostty -e rmpc
        ;;
esac
