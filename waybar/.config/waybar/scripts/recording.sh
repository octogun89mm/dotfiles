#!/bin/bash

# waybar-wf-recorder-status.sh
# Shows a flashing red dot in waybar when wf-recorder is recording

PID_FILE="/tmp/wf-recorder.pid"

# Function to check if wf-recorder is recording
is_recording() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        # ps -p checks if process with given PID exists
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 0 means true (recording)
        else
            # Clean up stale PID file
            rm -f "$PID_FILE"
            return 1  # 1 means false (not recording)
        fi
    fi
    return 1
}

# Main loop
# Waybar expects JSON output on each line
while true; do
    if is_recording; then
        # Calculate if we should show the dot (flash on/off every second)
        # Get current second from epoch time
        current_second=$(date +%s)
        
        # Use modulo to alternate: even seconds show dot, odd seconds hide it
        # % is modulo operator (remainder after division)
        if [ $((current_second % 2)) -eq 0 ]; then
            # Even second - show red dot
            # ● is unicode character U+25CF (black circle)
            # We color it with CSS, not in the text itself
            echo '{"text": "●", "class": "recording", "tooltip": "Recording active"}'
        else
            # Odd second - hide dot (show empty space to keep layout)
            echo '{"text": " ", "class": "recording", "tooltip": "Recording active"}'
        fi
    else
        # Not recording - show nothing (empty JSON)
        # Empty text and class makes it invisible in waybar
        echo '{"text": "", "class": "idle", "tooltip": ""}'
    fi
    
    # Sleep for 0.5 seconds for smooth flashing
    # This checks twice per second, so flashing is responsive
    sleep 0.5
done
