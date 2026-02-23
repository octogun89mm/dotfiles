#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

# List images with thumbnail:// prefix for preview
selected=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.jxl' \) \
    -printf '%f\n' | sort | while read -r file; do
        echo -en "$file\0icon\x1fthumbnail://$WALLPAPER_DIR/$file\n"
    done | rofi -dmenu -i -p "Wallpaper" -theme ~/.config/rofi/themes/wallpaper.rasi -show-icons)

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
