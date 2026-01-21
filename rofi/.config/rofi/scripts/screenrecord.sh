#!/bin/bash

# Screen recording rofi wrapper script
# A multi-level menu interface for wf-recorder
# Supports both Sway and Hyprland

# Configuration
RECORDINGS_DIR="$HOME/Videos/recordings"
PID_FILE="/tmp/wf-recorder.pid"
STATUS_FILE="/tmp/wf-recorder-status"
CONFIG_FILE="/tmp/wf-recorder-config"

# Detect compositor
is_hyprland() {
    [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]
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

# Quality presets
# These define bitrate (-b:v) and other encoding parameters
declare -A QUALITY_PRESETS
QUALITY_PRESETS[low]="-b:v 2M"
QUALITY_PRESETS[medium]="-b:v 5M"
QUALITY_PRESETS[high]="-b:v 10M"
QUALITY_PRESETS[ultra]="-b:v 20M"

# Ensure recordings directory exists
mkdir -p "$RECORDINGS_DIR"

# Function to check if wf-recorder is running
is_recording() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        # ps -p checks if process with given PID exists
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 0 means true in bash
        else
            rm -f "$PID_FILE" "$STATUS_FILE" "$CONFIG_FILE"
            return 1  # 1 means false in bash
        fi
    fi
    return 1
}

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

# Function to select recording area
select_area() {
    local area=$1
    case $area in
        "Fullscreen")
            echo ""  # Empty string means fullscreen
            ;;
        "Active window")
            geometry=$(get_active_window)
            if [ -n "$geometry" ]; then
                echo "$geometry"
            else
                echo "CANCEL"
            fi
            ;;
        "Select region")
            geometry=$(slurp 2>/dev/null)
            if [ -n "$geometry" ]; then
                echo "$geometry"
            else
                echo "CANCEL"
            fi
            ;;
        "Active output")
            geometry=$(get_active_output)
            if [ -n "$geometry" ]; then
                echo "$geometry"
            else
                echo "CANCEL"
            fi
            ;;
        *)
            echo "CANCEL"
            ;;
    esac
}

# Function to select audio input
select_audio() {
    local audio=$1
    case $audio in
        "No audio")
            echo "none"
            ;;
        "System audio")
            echo "system"
            ;;
        "Microphone")
            echo "mic"
            ;;
        "System + Microphone")
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
        "Low (2 Mbps)")
            echo "low"
            ;;
        "Medium (5 Mbps)")
            echo "medium"
            ;;
        "High (10 Mbps)")
            echo "high"
            ;;
        "Ultra (20 Mbps)")
            echo "ultra"
            ;;
        *)
            echo "CANCEL"
            ;;
    esac
}

# Function to get microphone device
get_mic_device() {
    # pactl lists all audio sources
    # grep filters for input devices (sources with "input" in name)
    # We want actual microphones, not monitor sources
    # head -n1 takes the first match
    pactl list sources short | grep -v monitor | grep input | head -n1 | awk '{print $2}'
}

# Function to get system audio monitor device
get_system_audio_device() {
    # Get the default sink's monitor source for capturing system audio
    # This captures audio output (what you hear) rather than input
    default_sink=$(pactl get-default-sink)
    if [ -n "$default_sink" ]; then
        echo "${default_sink}.monitor"
    else
        # Fallback: find any monitor source
        pactl list sources short | grep monitor | head -n1 | awk '{print $2}'
    fi
}

# Function to start recording with all parameters
start_recording() {
    local geometry=$1
    local audio_mode=$2
    local quality=$3

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$RECORDINGS_DIR/recording_${timestamp}.mp4"

    # Build command arguments as array (avoids eval issues with PID tracking)
    local -a cmd_args=()

    # Add geometry if recording a region
    if [ -n "$geometry" ]; then
        cmd_args+=(-g "$geometry")
    fi

    # Add quality settings (split into separate args)
    read -ra quality_args <<< "${QUALITY_PRESETS[$quality]}"
    cmd_args+=("${quality_args[@]}")

    # Add audio based on mode
    # wf-recorder uses --audio=<device> format, not separate flags
    case $audio_mode in
        "system")
            system_device=$(get_system_audio_device)
            if [ -n "$system_device" ]; then
                cmd_args+=("--audio=$system_device")
            else
                notify-send "Warning" "No system audio device found, recording without audio"
            fi
            ;;
        "mic")
            mic_device=$(get_mic_device)
            if [ -n "$mic_device" ]; then
                cmd_args+=("--audio=$mic_device")
            else
                notify-send "Warning" "No microphone found, recording without audio"
            fi
            ;;
        "both")
            system_device=$(get_system_audio_device)
            if [ -n "$system_device" ]; then
                cmd_args+=("--audio=$system_device")
                notify-send "Info" "Recording system audio. For mic+system, use PipeWire virtual sink."
            else
                cmd_args+=(--audio)
            fi
            ;;
    esac

    # Add output file
    cmd_args+=(-f "$output_file")

    # Execute wf-recorder directly (not through eval) to get correct PID
    wf-recorder "${cmd_args[@]}" &

    # Store PID and configuration
    echo $! > "$PID_FILE"
    echo "$output_file" > "$STATUS_FILE"
    echo "Area: $geometry, Audio: $audio_mode, Quality: $quality" > "$CONFIG_FILE"

    notify-send "Recording started" "Quality: $quality\nSaving to: $(basename "$output_file")"
}

# Function to stop recording
stop_recording() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")

        # Send SIGINT to wf-recorder (graceful stop to finalize video)
        kill -INT "$pid" 2>/dev/null

        # Wait for process to terminate (up to 5 seconds)
        for i in {1..10}; do
            if ! ps -p "$pid" > /dev/null 2>&1; then
                break
            fi
            sleep 0.5
        done

        # If still running, force kill
        if ps -p "$pid" > /dev/null 2>&1; then
            kill -TERM "$pid" 2>/dev/null
            sleep 0.5
        fi

        # Last resort: SIGKILL
        if ps -p "$pid" > /dev/null 2>&1; then
            kill -KILL "$pid" 2>/dev/null
        fi

        # Also kill any remaining wf-recorder processes (fallback)
        pkill -INT wf-recorder 2>/dev/null

        if [ -f "$STATUS_FILE" ]; then
            output_file=$(cat "$STATUS_FILE")
            notify-send "Recording stopped" "Saved: $(basename "$output_file")"
            rm -f "$STATUS_FILE"
        else
            notify-send "Recording stopped"
        fi

        rm -f "$PID_FILE" "$CONFIG_FILE"
    fi
}

# Main menu flow
main() {
    # Check if already recording
    if is_recording; then
        # If recording, offer to stop
        choice=$(show_menu "Recording Active" "Stop recording")
        if [ "$choice" = "Stop recording" ]; then
            stop_recording
        fi
        exit 0
    fi
    
    # Step 1: Select area
    area_options="Fullscreen\nActive window\nSelect region\nActive output"
    area=$(show_menu "Select Area" "$area_options")
    
    # Check for cancellation (empty selection)
    # -z tests if string is empty
    if [ -z "$area" ]; then
        exit 0
    fi
    
    geometry=$(select_area "$area")
    if [ "$geometry" = "CANCEL" ]; then
        notify-send "Recording cancelled" "No region selected"
        exit 0
    fi
    
    # Step 2: Select audio
    audio_options="No audio\nSystem audio\nMicrophone\nSystem + Microphone"
    audio_choice=$(show_menu "Select Audio" "$audio_options")
    
    if [ -z "$audio_choice" ]; then
        exit 0
    fi
    
    audio_mode=$(select_audio "$audio_choice")
    if [ "$audio_mode" = "CANCEL" ]; then
        exit 0
    fi
    
    # Step 3: Select quality
    quality_options="Low (2 Mbps)\nMedium (5 Mbps)\nHigh (10 Mbps)\nUltra (20 Mbps)"
    quality_choice=$(show_menu "Select Quality" "$quality_options")
    
    if [ -z "$quality_choice" ]; then
        exit 0
    fi
    
    quality=$(select_quality "$quality_choice")
    if [ "$quality" = "CANCEL" ]; then
        exit 0
    fi
    
    # Start recording with all selected parameters
    start_recording "$geometry" "$audio_mode" "$quality"
}

# Run main function
main
