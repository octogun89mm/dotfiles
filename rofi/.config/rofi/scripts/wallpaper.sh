#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# List image files with icons and let user pick one
selected=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.jxl' \) \
    -printf '%f\n' | sort | rofi -dmenu -i -p "Wallpaper")

[ -z "$selected" ] && exit 0

wallpaper="$WALLPAPER_DIR/$selected"

# Apply wallpaper
hyprctl hyprpaper wallpaper ",$wallpaper"

# Persist in hyprpaper.conf
cat > "$HYPRPAPER_CONF" <<EOF
splash = false

wallpaper {
    monitor =
    path = $wallpaper
}
EOF

notify-send -u low -t 3000 "Wallpaper" "Set to $selected"
