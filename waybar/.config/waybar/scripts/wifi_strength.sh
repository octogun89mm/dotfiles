#!/bin/bash

INTERFACE="wlan1"  # Replace with your Wi-Fi interface

# Get signal strength as a percentage from nmcli
SIGNAL=$(nmcli -f IN-USE,SIGNAL dev wifi | grep '^*' | awk '{print $2}')

# If no connection, default to 0
echo ${SIGNAL:-0}
