#!/bin/bash

# Screenshot rofi wrapper script
# A multi-level menu interface for taking screenshots
# Supports both Sway (grim/slurp) and Hyprland (hyprshot)

# Configuration
SCREENSHOTS_DIR="$HOME/Pictures/screenshots"
TEMP_FILE="/tmp/screenshot.png"

# Detect compositor
is_hyprland() {
    [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]
}

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
    # -dmenu: dmenu compatibility mode
    # -i: case insensitive
    # -p: prompt text
    # -no-custom: only allow selecting from list, no custom input
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
    if is_hyprland; then
        hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    else
        swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
    fi
}

# Function to get active output (monitor) geometry
get_active_output() {
    if is_hyprland; then
        hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width)x\(.height)"'
    else
        swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .rect | "\(.x),\(.y) \(.width)x\(.height)"'
    fi
}

# Function to copy image to clipboard
# Uses wl-copy for Wayland clipboard
copy_to_clipboard() {
    local file=$1
    # wl-copy copies to Wayland clipboard
    # -t specifies MIME type
    # < redirects file content as input
    wl-copy -t image/png < "$file"
}

# Function to take screenshot using hyprshot (for Hyprland)
# Hyprshot handles notifications automatically
take_screenshot_hyprshot() {
    local area_mode=$1
    local action_mode=$2

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="screenshot_${timestamp}.png"

    # Map area mode to hyprshot mode
    local hyprshot_mode=""
    case $area_mode in
        "fullscreen")
            # Hyprshot doesn't have fullscreen mode, use output for current monitor
            hyprshot_mode="output"
            ;;
        "window")
            hyprshot_mode="window"
            ;;
        "region")
            hyprshot_mode="region"
            ;;
        "output")
            hyprshot_mode="output"
            ;;
    esac

    # Build and execute hyprshot command based on action
    case $action_mode in
        "clipboard")
            hyprshot -m "$hyprshot_mode" --clipboard-only
            ;;
        "save")
            hyprshot -m "$hyprshot_mode" -o "$SCREENSHOTS_DIR" -f "$filename" --silent
            notify-send "Screenshot saved" "Saved: $filename"
            ;;
        "both")
            hyprshot -m "$hyprshot_mode" -o "$SCREENSHOTS_DIR" -f "$filename"
            ;;
    esac
}

# Function to take screenshot using grim (for Sway)
take_screenshot() {
    local area_mode=$1
    local action_mode=$2
    local quality=$3
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$SCREENSHOTS_DIR/screenshot_${timestamp}.png"
    local geometry=""
    
    # Get geometry based on area mode
    case $area_mode in
        "fullscreen")
            # No geometry needed, grim captures all outputs by default
            geometry=""
            ;;
        "window")
            # Get geometry of currently focused window
            geometry=$(get_active_window)
            if [ -z "$geometry" ]; then
                notify-send "Screenshot failed" "Could not get active window"
                return 1
            fi
            ;;
        "region")
            # Let user select region with slurp
            # slurp returns geometry or nothing if cancelled
            geometry=$(slurp 2>/dev/null)
            if [ -z "$geometry" ]; then
                notify-send "Screenshot cancelled" "No region selected"
                return 1
            fi
            ;;
        "output")
            # Get geometry of currently focused output (monitor)
            geometry=$(get_active_output)
            if [ -z "$geometry" ]; then
                notify-send "Screenshot failed" "Could not get active output"
                return 1
            fi
            ;;
    esac
    
    # Build grim command
    local cmd="grim"
    
    # Add geometry if not fullscreen
    # -n tests if string is not empty
    if [ -n "$geometry" ]; then
        # -g specifies geometry to capture
        cmd="$cmd -g \"$geometry\""
    fi
    
    # Add quality settings
    # ${QUALITY_PRESETS[$quality]} looks up quality in associative array
    cmd="$cmd ${QUALITY_PRESETS[$quality]}"
    
    # Determine output based on action mode
    case $action_mode in
        "save")
            # Save directly to file
            cmd="$cmd \"$output_file\""
            ;;
        "clipboard")
            # Save to temp file first, then copy
            cmd="$cmd \"$TEMP_FILE\""
            ;;
        "both")
            # Save to file and copy
            cmd="$cmd \"$output_file\""
            ;;
    esac
    
    # Execute grim command
    # eval allows the string to be executed as a command
    eval "$cmd"
    
    # Check if grim succeeded
    # $? contains exit code of last command (0 = success)
    if [ $? -ne 0 ]; then
        notify-send "Screenshot failed" "grim returned an error"
        return 1
    fi
    
    # Handle clipboard action
    case $action_mode in
        "clipboard")
            copy_to_clipboard "$TEMP_FILE"
            notify-send "Screenshot copied" "Image copied to clipboard"
            # Clean up temp file
            rm -f "$TEMP_FILE"
            ;;
        "both")
            copy_to_clipboard "$output_file"
            notify-send "Screenshot saved and copied" "Saved: $(basename "$output_file")"
            ;;
        "save")
            notify-send "Screenshot saved" "Saved: $(basename "$output_file")"
            ;;
    esac
}

# Main menu flow
main() {
    # Step 1: Select area
    area_options="Fullscreen\nActive window\nSelect region\nActive output"
    area=$(show_menu "Select Area" "$area_options")

    # Check for cancellation (empty selection)
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

    # Use hyprshot on Hyprland (no quality option needed)
    if is_hyprland; then
        take_screenshot_hyprshot "$area_mode" "$action_mode"
        exit 0
    fi

    # Step 3: Select quality (grim only)
    quality_options="Fast (No compression)\nBalanced (Default)\nBest (Max compression)"
    quality_choice=$(show_menu "Select Quality" "$quality_options")

    if [ -z "$quality_choice" ]; then
        exit 0
    fi

    quality=$(select_quality "$quality_choice")
    if [ "$quality" = "CANCEL" ]; then
        exit 0
    fi

    # Take screenshot with grim
    take_screenshot "$area_mode" "$action_mode" "$quality"
}

# Run main function
main
