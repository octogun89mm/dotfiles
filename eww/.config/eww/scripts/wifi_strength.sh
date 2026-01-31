#!/bin/bash
SIGNAL=$(nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\*' | cut -d: -f2)
if [ -z "$SIGNAL" ]; then
    SIGNAL=$(nmcli -t -f GENERAL.STATE,WIFI.SIGNAL dev show | grep 'wifi' -A1 | grep SIGNAL | cut -d: -f2 | tr -d ' ')
fi
if [ -z "$SIGNAL" ] || [ "$SIGNAL" == "--" ]; then
    echo "0"
else
    echo "$SIGNAL"
fi
