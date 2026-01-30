#!/usr/bin/env bash

# Dunst notification history viewer for rofi
# Requires: dunst, jq, rofi

HISTORY=$(dunstctl history | jq -r '.data[0][]')
COUNT=$(echo "$HISTORY" | jq -s 'length')

if [ "$COUNT" -eq 0 ] || [ -z "$HISTORY" ]; then
    rofi -e "No notifications in history."
    exit 0
fi

# Build menu entries: "appname: summary"
ENTRIES=$(echo "$HISTORY" | jq -r '"\(.id.data)\t\(.appname.data): \(.summary.data)"')

# First menu: list notifications + clear all option
SELECTION=$(echo -e "Clear all notifications\n$(echo "$ENTRIES" | cut -f2)" | \
    rofi -dmenu -p "Notifications ($COUNT)" -i)

[ -z "$SELECTION" ] && exit 0

if [ "$SELECTION" = "Clear all notifications" ]; then
    dunstctl close-all
    dunstctl history-clear
    exit 0
fi

# Find the ID of the selected notification
SELECTED_ID=$(echo "$ENTRIES" | grep -F "$SELECTION" | head -1 | cut -f1)

# Show details and offer actions
BODY=$(echo "$HISTORY" | jq -r --argjson id "$SELECTED_ID" 'select(.id.data == $id) | .body.data')
APP=$(echo "$HISTORY" | jq -r --argjson id "$SELECTED_ID" 'select(.id.data == $id) | .appname.data')
SUMMARY=$(echo "$HISTORY" | jq -r --argjson id "$SELECTED_ID" 'select(.id.data == $id) | .summary.data')

DETAIL="[$APP] $SUMMARY"
[ -n "$BODY" ] && [ "$BODY" != "" ] && DETAIL="$DETAIL\n$BODY"

ACTION=$(echo -e "Pop up notification\nDelete notification\nBack" | \
    rofi -dmenu -p "Action" -mesg "$DETAIL" -i)

case "$ACTION" in
    "Pop up notification")
        dunstctl history-pop "$SELECTED_ID"
        ;;
    "Delete notification")
        dunstctl history-rm "$SELECTED_ID"
        ;;
    "Back")
        exec "$0"
        ;;
esac

exit 0
