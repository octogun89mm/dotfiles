#!/bin/bash

set -euo pipefail

CACHE_DIR="$HOME/.cache/speak"
mkdir -p "$CACHE_DIR"

mapfile -t txt_files < <(ls -t "$CACHE_DIR"/*.txt 2>/dev/null || true)

displays=()
hashes=()
for f in "${txt_files[@]}"; do
    hash="$(basename "$f" .txt)"
    [[ -s "$CACHE_DIR/$hash.wav" ]] || continue
    text="$(tr '\n' ' ' < "$f" | head -c 200)"
    displays+=("$text")
    hashes+=("$hash")
done

selection="$(
    printf '%s\n' "${displays[@]}" | rofi -dmenu \
        -i \
        -p "speak" \
        -format 'i s' \
        || true
)"

[[ -z "$selection" ]] && exit 0

idx="${selection%% *}"
str="${selection#* }"

if [[ "$idx" == "-1" ]]; then
    exec speak "$str"
else
    hash="${hashes[$idx]}"
    ffplay -nodisp -autoexit -loglevel quiet "$CACHE_DIR/$hash.wav"
    touch "$CACHE_DIR/$hash.wav" "$CACHE_DIR/$hash.txt"
fi
