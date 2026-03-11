#!/bin/bash

# Screenshot rofi wrapper script
# A multi-level menu interface for taking screenshots
# Supports Wayland compositors (grim/slurp)

# Configuration
SCREENSHOTS_DIR="$HOME/Pictures/screenshots"
TEMP_FILE="/tmp/screenshot.png"

# Quality presets for PNG compression
# -l sets compression level (0-9, where 9 is maximum compression)
declare -A QUALITY_PRESETS
QUALITY_PRESETS[fast]="-l 0"
QUALITY_PRESETS[balanced]="-l 6"
QUALITY_PRESETS[best]="-l 9"

# Ensure screenshots directory exists
mkdir -p "$SCREENSHOTS_DIR"

# Function to show rofi menu and get selection
# $1 = prompt text
# $2 = options (newline-separated string)
show_menu() {
    local prompt=$1
    local options=$2
    echo -e "$options" | rofi -dmenu -i -p "$prompt" -no-custom
}

# Function to select screenshot area
select_area() {
    local area=$1
    case $area in
        "Fullscreen")
            echo "fullscreen"
            ;;
        "Active window")
            echo "window"
            ;;
        "Select region")
            echo "region"
            ;;
        "Active output")
            echo "output"
            ;;
        "All screens")
            echo "allscreens"
            ;;
        *)
            echo "CANCEL"
            ;;
    esac
}

# Function to select action
select_action() {
    local action=$1
    case $action in
        "Save to file")
            echo "save"
            ;;
        "Copy to clipboard")
            echo "clipboard"
            ;;
        "Both")
            echo "both"
            ;;
        *)
            echo "CANCEL"
            ;;
    esac
}

# Function to select quality
select_quality() {
    local quality=$1
    case $quality in
        "Fast (No compression)")
            echo "fast"
            ;;
        "Balanced (Default)")
            echo "balanced"
            ;;
        "Best (Max compression)")
            echo "best"
            ;;
        *)
            echo "CANCEL"
            ;;
    esac
}

# Function to get active window geometry
get_active_window() {
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    else
        swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
    fi
}

# Function to get active output (monitor) geometry
get_active_output() {
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"'
    else
        swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
    fi
}

# Function to copy image to clipboard
copy_to_clipboard() {
    local file=$1
    wl-copy -t image/png < "$file"
}

# Function to take screenshot using grim
take_screenshot() {
    local area_mode=$1
    local action_mode=$2
    local quality=$3

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$SCREENSHOTS_DIR/screenshot_${timestamp}.png"
    local geometry=""

    # Get geometry based on area mode
    case $area_mode in
        "fullscreen"|"allscreens")
            geometry=""
            ;;
        "window")
            geometry=$(get_active_window)
            if [ -z "$geometry" ]; then
                notify-send -a "Screenshot" "Screenshot failed" "Could not get active window"
                return 1
            fi
            ;;
        "region")
            geometry=$(slurp 2>/dev/null)
            if [ -z "$geometry" ]; then
                notify-send -a "Screenshot" "Screenshot cancelled" "No region selected"
                return 1
            fi
            ;;
        "output")
            geometry=$(get_active_output)
            if [ -z "$geometry" ]; then
                notify-send -a "Screenshot" "Screenshot failed" "Could not get active output"
                return 1
            fi
            ;;
    esac

    sleep 1

    # Build grim command
    local cmd="grim"

    if [ -n "$geometry" ]; then
        cmd="$cmd -g \"$geometry\""
    fi

    cmd="$cmd ${QUALITY_PRESETS[$quality]}"

    case $action_mode in
        "save")
            cmd="$cmd \"$output_file\""
            ;;
        "clipboard")
            cmd="$cmd \"$TEMP_FILE\""
            ;;
        "both")
            cmd="$cmd \"$output_file\""
            ;;
    esac

    eval "$cmd"

    if [ $? -ne 0 ]; then
        notify-send -a "Screenshot" "Screenshot failed" "grim returned an error"
        return 1
    fi

    case $action_mode in
        "clipboard")
            copy_to_clipboard "$TEMP_FILE"
            notify-send -a "Screenshot" -i "$TEMP_FILE" "Screenshot copied" "Image copied to clipboard"
            rm -f "$TEMP_FILE"
            ;;
        "both")
            copy_to_clipboard "$output_file"
            notify-send -a "Screenshot" -i "$output_file" "Screenshot saved and copied" "Saved: $(basename "$output_file")"
            ;;
        "save")
            notify-send -a "Screenshot" -i "$output_file" "Screenshot saved" "Saved: $(basename "$output_file")"
            ;;
    esac
}

# Main menu flow
main() {
    # Step 1: Select area
    area_options="Fullscreen\nActive window\nSelect region\nActive output\nAll screens"
    area=$(show_menu "Select Area" "$area_options")

    if [ -z "$area" ]; then
        exit 0
    fi

    area_mode=$(select_area "$area")
    if [ "$area_mode" = "CANCEL" ]; then
        exit 0
    fi

    # Step 2: Select action
    action_options="Save to file\nCopy to clipboard\nBoth"
    action=$(show_menu "Select Action" "$action_options")

    if [ -z "$action" ]; then
        exit 0
    fi

    action_mode=$(select_action "$action")
    if [ "$action_mode" = "CANCEL" ]; then
        exit 0
    fi

    # Step 3: Select quality
    quality_options="Fast (No compression)\nBalanced (Default)\nBest (Max compression)"
    quality_choice=$(show_menu "Select Quality" "$quality_options")

    if [ -z "$quality_choice" ]; then
        exit 0
    fi

    quality=$(select_quality "$quality_choice")
    if [ "$quality" = "CANCEL" ]; then
        exit 0
    fi

    take_screenshot "$area_mode" "$action_mode" "$quality"
}

# Run main function
main
