#!/bin/bash

set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mapfile -t entries < <(cliphist list | tr -d '\000')

if [[ ${#entries[@]} -eq 0 ]]; then
    exit 0
fi

rows_file="$tmpdir/rows"

for idx in "${!entries[@]}"; do
    entry="${entries[$idx]}"
    preview="${entry#*$'\t'}"
    icon_path=""

    if [[ "$preview" == "[[ binary data "* ]]; then
        clip_file="$tmpdir/clip-$idx"
        if printf '%s\n' "$entry" | cliphist decode > "$clip_file" 2>/dev/null; then
            mime_type="$(file --brief --mime-type "$clip_file" 2>/dev/null || true)"
            if [[ "$mime_type" == image/* ]]; then
                icon_path="$clip_file"
            fi
        fi
    fi

    if [[ -n "$icon_path" ]]; then
        printf '%s\0icon\x1f%s\n' "$preview" "$icon_path" >> "$rows_file"
    else
        printf '%s\n' "$preview" >> "$rows_file"
    fi
done

selection="$(
    rofi -dmenu \
        -p "Clipboard History" \
        -i \
        -show-icons \
        -format i \
        -theme-str 'listview { columns: 1; } element { children: [ element-icon, element-text ]; } element-icon { size: 3em; }' \
        < "$rows_file"
)"

if [[ -z "${selection:-}" ]]; then
    exit 0
fi

printf '%s\n' "${entries[$selection]}" | cliphist decode | wl-copy
