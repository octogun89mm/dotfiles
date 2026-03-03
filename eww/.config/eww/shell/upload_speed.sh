#!/bin/bash
INTERFACE="wlan1"
STATE_FILE="/tmp/tx_prev_eww_$INTERFACE"
TX_PREV=$(cat "$STATE_FILE" 2>/dev/null || cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
TX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
echo "$TX_NEXT" > "$STATE_FILE"
echo "scale=2; ($TX_NEXT - $TX_PREV) / 1048576 / 2" | bc | xargs printf "%05.2f"
