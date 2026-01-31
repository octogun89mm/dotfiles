#!/bin/bash
# Disk usage for a given mount point
# Usage: disk_usage.sh /mount/path
# Output: "used/totalG" e.g. "124/256G"
df -BG "$1" 2>/dev/null | awk 'NR==2 {gsub("G",""); printf "%.0f/%.0fG", $3, $2}'
