#!/usr/bin/env bash
#
# Daemon Manager for EWW Bar C binaries
# Starts/stops daemon processes that continuously update state files
#

SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SHELL_DIR")"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
STATE_DIR="$SCRIPTS_DIR/state"
PID_DIR="$SCRIPTS_DIR/pids"
BIN="$SCRIPTS_DIR/eww-bar"

mkdir -p "$STATE_DIR" "$PID_DIR"

# Map of variable names to their subcommands
declare -A DAEMONS=(
    ["bar_workspaces"]="workspaces"
    ["bar_window_title_0"]="window-title 0"
    ["bar_window_title_1"]="window-title 1"
    ["bar_submap"]="submap"
    ["bar_language"]="language"
    ["bar_volume"]="volume"
    ["mpd_data"]="mpd"
    ["bar_layout_0"]="layout 0"
    ["bar_layout_1"]="layout 1"
    ["bar_wincount_0"]="wincount 0"
    ["bar_wincount_1"]="wincount 1"
)

start_daemon() {
    local name="$1"
    local cmd="$2"
    local pidfile="$PID_DIR/$name.pid"
    local statefile="$STATE_DIR/$name.state"

    # Check if already running
    if [[ -f "$pidfile" ]]; then
        local pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$pidfile"
    fi

    # Initialize state file
    : > "$statefile"

    # Start daemon in background using stdbuf for line buffering
    # The C program outputs lines, we use tail to keep only the latest
    (
        while true; do
            stdbuf -oL "$BIN" $cmd 2>/dev/null >> "$statefile"
            # Keep only the last line
            tail -n 1 "$statefile" > "$statefile.new" && mv "$statefile.new" "$statefile"
            sleep 1
        done
    ) &

    echo $! > "$pidfile"
}

stop_daemon() {
    local name="$1"
    local pidfile="$PID_DIR/$name.pid"
    
    if [[ -f "$pidfile" ]]; then
        local pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            sleep 0.5
            kill -9 "$pid" 2>/dev/null
        fi
        rm -f "$pidfile"
    fi
}

start_all() {
    for name in "${!DAEMONS[@]}"; do
        start_daemon "$name" "${DAEMONS[$name]}"
    done
    echo "Started ${#DAEMONS[@]} daemons"
}

stop_all() {
    for name in "${!DAEMONS[@]}"; do
        stop_daemon "$name"
    done
    echo "Stopped all daemons"
}

restart_all() {
    stop_all
    sleep 0.5
    start_all
}

status() {
    for name in "${!DAEMONS[@]}"; do
        local pidfile="$PID_DIR/$name.pid"
        local statefile="$STATE_DIR/$name.state"
        if [[ -f "$pidfile" ]]; then
            local pid=$(cat "$pidfile")
            if kill -0 "$pid" 2>/dev/null; then
                local content=""
                if [[ -f "$statefile" ]]; then
                    content=$(head -c 50 "$statefile")
                fi
                echo "✓ $name (PID $pid): $content"
            else
                echo "✗ $name: dead (stale pidfile)"
            fi
        else
            echo "✗ $name: not running"
        fi
    done
}

case "${1:-}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
