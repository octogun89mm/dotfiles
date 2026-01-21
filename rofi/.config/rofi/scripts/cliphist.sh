#!/bin/bash

# Clipboard history manager for Wayland using cliphist and rofi
# Requires: cliphist, wl-clipboard, rofi

# cliphist list outputs the history
# rofi -dmenu displays it in a menu for selection
# cliphist decode converts the selected item back to original format
# wl-copy puts it on the clipboard
cliphist list | \
    rofi -dmenu -p "Clipboard History" -i | \
    cliphist decode | \
    wl-copy
