#!/bin/bash

set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_file="$cache_dir/rofi-unicode-picker-v2.txt"

fallback_list=$'😀 grinning face emoji smileys\n😂 face with tears of joy emoji smileys\n❤️ red heart emoji heart\n👍 thumbs up emoji hand\n🔥 fire emoji nature\n✨ sparkles emoji symbols\n🎉 party popper emoji celebration\n🚀 rocket emoji travel\n— em dash unicode dash punctuation\n– en dash unicode dash punctuation\n← left arrow unicode symbol\n→ right arrow unicode symbol\n∞ infinity unicode math symbol\n★ black star unicode symbol\n♥ black heart suit unicode symbol\n☀ black sun with rays unicode symbol\n⚡ high voltage sign unicode symbol\n'

generate_emoji_list() {
    python3 - <<'PY'
import os
import re
import sys
import unicodedata
from pathlib import Path


def find_emoji_labels():
    candidates = sorted(Path("/usr/share/emacs").glob("*/lisp/international/emoji-labels.el"))
    return candidates[0] if candidates else None


def tokenize(source):
    tokens = []
    i = 0
    length = len(source)
    while i < length:
        char = source[i]
        if char.isspace():
            i += 1
            continue
        if char == ";":
            while i < length and source[i] != "\n":
                i += 1
            continue
        if char in "()":
            tokens.append(char)
            i += 1
            continue
        if char in ("'", "`"):
            i += 1
            continue
        if char == '"':
            i += 1
            chunk = []
            while i < length:
                char = source[i]
                if char == "\\" and i + 1 < length:
                    chunk.append(source[i + 1])
                    i += 2
                    continue
                if char == '"':
                    i += 1
                    break
                chunk.append(char)
                i += 1
            tokens.append("".join(chunk))
            continue

        start = i
        while i < length and not source[i].isspace() and source[i] not in "()'`\";":
            i += 1
        tokens.append(source[start:i])
    return tokens


def parse_expr(tokens, index=0):
    token = tokens[index]
    if token == "(":
        index += 1
        items = []
        while tokens[index] != ")":
            value, index = parse_expr(tokens, index)
            items.append(value)
        return items, index + 1
    return token, index + 1


def looks_like_emoji(text):
    return any(ord(char) > 127 for char in text) or text in set("#*0123456789")


def normalize_tag(text):
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def emoji_description(emoji, path):
    stripped = [char for char in emoji if ord(char) not in (0x200D, 0xFE0F, 0x20E3)]
    pieces = []

    for char in stripped:
        try:
            name = unicodedata.name(char).lower()
        except ValueError:
            continue
        pieces.append(name)

    description = " ".join(pieces)
    if not description:
        description = " ".join(path) if path else "emoji"

    tags = " ".join(normalize_tag(part) for part in path if part)
    if tags and tags not in description:
        description = f"{description} {tags}".strip()
    return re.sub(r"\s+", " ", description).strip()


def flatten(node, path, results, seen):
    if isinstance(node, str):
        if looks_like_emoji(node) and node not in seen:
            seen.add(node)
            results.append((node, emoji_description(node, path)))
        return

    if not isinstance(node, list) or not node:
        return

    head = node[0]
    next_path = path
    if isinstance(head, str) and not looks_like_emoji(head):
        next_path = path + [normalize_tag(head)]
        children = node[1:]
    else:
        children = node

    for child in children:
        flatten(child, next_path, results, seen)


def add_unicode_symbols(results, seen):
    category_labels = {
        "Sm": "math symbol",
        "Sc": "currency symbol",
        "Sk": "modifier symbol",
        "So": "other symbol",
        "Pd": "dash punctuation",
    }

    for codepoint in range(0x20, sys.maxunicode + 1):
        char = chr(codepoint)
        if char in seen or not char.isprintable():
            continue

        category = unicodedata.category(char)
        if not (category.startswith("S") or category == "Pd"):
            continue

        try:
            name = unicodedata.name(char).lower()
        except ValueError:
            continue

        seen.add(char)
        label = category_labels.get(category, "symbol")
        results.append((char, f"{name} unicode {label}"))


emoji_labels = find_emoji_labels()
if emoji_labels is None:
    sys.exit(1)

source = emoji_labels.read_text(encoding="utf-8")
match = re.search(r"\(defconst\s+emoji--labels\s+'", source)
if match is None:
    sys.exit(1)

start = source.find("(", match.end())
if start == -1:
    sys.exit(1)

tree, _ = parse_expr(tokenize(source[start:]))
items = []
seen = set()
flatten(tree, [], items, seen)
add_unicode_symbols(items, seen)

for emoji, description in items:
    print(f"{emoji} {description}")
PY
}

get_formatted_list() {
    mkdir -p "$cache_dir"

    if [ -s "$cache_file" ]; then
        cat "$cache_file"
        return
    fi

    if generate_emoji_list >"$cache_file".tmp 2>/dev/null; then
        mv "$cache_file".tmp "$cache_file"
        cat "$cache_file"
        return
    fi

    rm -f "$cache_file".tmp
    printf '%s' "$fallback_list"
}

formatted_list="$(get_formatted_list)"

selected=$(printf '%s' "$formatted_list" | rofi -i -dmenu -p "Unicode" -no-custom)

if [ -z "$selected" ]; then
    exit 0
fi

char="${selected%% *}"
printf '%s' "$char" | wl-copy
notify-send -a "Emoji Picker" "Unicode Picker" "Copied: $char" -t 2000
