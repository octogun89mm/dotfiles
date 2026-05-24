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
        exec kitty
        ;;
    "Dropdown terminal")
        exec kitty --class scratchpad -o background_opacity=0.9
        ;;
    "Ranger")
        exec kitty -e ranger
        ;;
    "Neovim")
        exec kitty --class nvim -e nvim
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
        exec kitty --class newsboat -e newsboat
        ;;
    "Music player")
        exec kitty -e rmpc
        ;;
esac
