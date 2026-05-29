#!/bin/bash

INTERFACE="wlan1"  # Replace with your interface
STATE_FILE="/tmp/tx_prev_$INTERFACE"

TX_PREV=$(cat $STATE_FILE 2>/dev/null || cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
TX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

echo $TX_NEXT > $STATE_FILE

TX_SPEED=$(echo "scale=2; (($TX_NEXT - $TX_PREV) / 1024 / 1024 / 2)" | bc)

printf "%05.2f\n" $TX_SPEED
