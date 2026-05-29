#!/bin/bash

INTERFACE="wlan1"  # Replace with your interface
STATE_FILE="/tmp/rx_prev_$INTERFACE"

RX_PREV=$(cat $STATE_FILE 2>/dev/null || cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
RX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)

echo $RX_NEXT > $STATE_FILE

RX_SPEED=$(echo "scale=2; (($RX_NEXT - $RX_PREV) / 1024 / 1024 / 2)" | bc)

printf "%05.2f\n" $RX_SPEED
