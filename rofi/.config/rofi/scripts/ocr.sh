#!/usr/bin/env bash

# OCR script using grim, slurp, tesseract, wl-copy, and notify-send
# Select a region on screen and extract text to clipboard

set -euo pipefail

TMP_IMG=$(mktemp --suffix=.png)
trap 'rm -f "$TMP_IMG"' EXIT

# Select region and capture screenshot
if ! grim -g "$(slurp)" "$TMP_IMG" 2>/dev/null; then
    notify-send -u low "OCR" "Selection cancelled"
    exit 1
fi

# Run OCR on the captured image
TEXT=$(tesseract "$TMP_IMG" - 2>/dev/null | sed '/^$/d')

if [[ -z "$TEXT" ]]; then
    notify-send -u normal "OCR" "No text detected"
    exit 0
fi

# Copy to clipboard
printf '%s' "$TEXT" | wl-copy

# Show notification with preview of extracted text
PREVIEW="${TEXT:0:100}"
[[ ${#TEXT} -gt 100 ]] && PREVIEW="$PREVIEW..."

notify-send -u normal "OCR" "Copied to clipboard:\n$PREVIEW"
