#!/bin/bash
# CPU usage percentage using /proc/stat with state file
# Non-blocking alternative to top -bn1

STATE_FILE="/tmp/eww_cpu_prev"

# Read current CPU stats
read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat

total=$((user + nice + system + idle + iowait + irq + softirq + steal))

if [ -f "$STATE_FILE" ]; then
    read -r prev_total prev_idle < "$STATE_FILE"
    diff_total=$((total - prev_total))
    diff_idle=$((idle - prev_idle))
    if [ "$diff_total" -gt 0 ]; then
        usage=$(( (diff_total - diff_idle) * 100 / diff_total ))
    else
        usage=0
    fi
else
    usage=0
fi

echo "$total $idle" > "$STATE_FILE"
printf "%d" "$usage"
