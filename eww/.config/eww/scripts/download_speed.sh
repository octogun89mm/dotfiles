#!/bin/bash
INTERFACE="wlan1"
STATE_FILE="/tmp/rx_prev_eww_$INTERFACE"
RX_PREV=$(cat "$STATE_FILE" 2>/dev/null || cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
RX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
echo "$RX_NEXT" > "$STATE_FILE"
echo "scale=2; ($RX_NEXT - $RX_PREV) / 1048576 / 2" | bc | xargs printf "%05.2f"
