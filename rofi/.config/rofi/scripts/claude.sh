#!/usr/bin/env bash

# Claude Code launcher for rofi

# If no argument, show menu options
if [ -z "$1" ]; then
    echo "Quick Review"
    echo "Write Tests"
    echo "Refactor Code"
    echo "Debug Issue"
    echo "Explain Code"
    echo "Custom Task"
    exit 0
fi

# Get the task description from the second argument
TASK_DESC="$2"

# Default prompts for each task type
case "$1" in
    "Quick Review")
        PROMPT="Review the code in the current directory for bugs, security issues, and code quality. Be concise."
        ;;
    "Write Tests")
        PROMPT="Write unit tests for the code in the current directory. Focus on edge cases and coverage."
        ;;
    "Refactor Code")
        PROMPT="Refactor the code in the current directory to improve readability, performance, and maintainability."
        ;;
    "Debug Issue")
        PROMPT="Debug the issue in the current directory. Look for errors, race conditions, and logic bugs."
        ;;
    "Explain Code")
        PROMPT="Explain what the code in the current directory does. Provide a summary of the architecture and key functions."
        ;;
    "Custom Task")
        if [ -z "$TASK_DESC" ]; then
            # Launch rofi again to get custom task description
            CUSTOM=$(rofi -dmenu -p "Describe your task:" -theme wallust)
            if [ -z "$CUSTOM" ]; then
                exit 1
            fi
            PROMPT="$CUSTOM"
        else
            PROMPT="$TASK_DESC"
        fi
        ;;
    *)
        exit 1
        ;;
esac

# Get current directory or use argument if provided
WORKDIR="${3:-$(pwd)}"

# Launch Claude Code in a tmux session
SESSION_NAME="claude-$$"

# Create detached tmux session
tmux new-session -d -s "$SESSION_NAME" -x 140 -y 40

# Change to workdir and launch claude
tmux send-keys -t "$SESSION_NAME" "cd '$WORKDIR' && claude -p '$PROMPT' --max-turns 15" Enter

# Show notification
notify-send "Claude Code" "Started: $1 in $WORKDIR"

exit 0
