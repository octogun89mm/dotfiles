#!/bin/bash

# Displays: GPU usage % | VRAM used/total GB | Temperature °C

# Get GPU utilization percentage
gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

# Get VRAM used and total in MB
vram_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
vram_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

# Get temperature in Celsius
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

# Convert VRAM from MB to GB with 1 decimal using bc
# bc by itself can output ".2" without leading zero, so we use printf to format it
# This gives us "0.2" instead of ".2"
vram_used_gb=$(echo "scale=1; $vram_used / 1024" | bc)
vram_total_gb=$(echo "scale=1; $vram_total / 1024" | bc)
# printf "%0.1f" adds leading zero if needed and ensures 1 decimal place
vram_used_gb=$(printf "%0.1f" "$vram_used_gb")
vram_total_gb=$(printf "%0.1f" "$vram_total_gb")

# Format GPU usage to 1 decimal
gpu_usage=$(printf "%.1f" "$gpu_usage")

# Output with fixed-width formatting using printf
printf "%5s%% %4sG/%4sG %3s°C\n" "$gpu_usage" "$vram_used_gb" "$vram_total_gb" "$temp"

