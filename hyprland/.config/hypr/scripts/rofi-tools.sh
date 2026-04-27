#!/usr/bin/env bash

set -euo pipefail

selection=$(
    printf '%s\n' \
        "Screenshot" \
        "Screen record" \
        "Clipboard history" \
        "Emoji/symbol picker" \
        "OCR" \
        "Todo" \
        "Wallpaper picker" \
        "Speak (TTS)" \
        "Power menu" |
    rofi -dmenu -i -p "Tools" -no-custom
)

[ -z "$selection" ] && exit 0

case "$selection" in
    "Screenshot")
        exec ~/.config/rofi/scripts/screenshot.sh
        ;;
    "Screen record")
        exec ~/.config/rofi/scripts/screenrecord.sh
        ;;
    "Clipboard history")
        exec ~/.config/rofi/scripts/cliphist.sh
        ;;
    "Emoji/symbol picker")
        exec ~/.config/rofi/scripts/emojis.sh
        ;;
    "OCR")
        exec ~/.config/rofi/scripts/ocr.sh
        ;;
    "Todo")
        exec ~/.config/rofi/scripts/todo.sh
        ;;
    "Wallpaper picker")
        exec ~/.config/rofi/scripts/wallpaper.sh
        ;;
    "Speak (TTS)")
        exec ~/.config/rofi/scripts/speak.sh
        ;;
    "Power menu")
        exec rofi -show power
        ;;
esac
