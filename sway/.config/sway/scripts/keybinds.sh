#!/usr/bin/env bash

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config"

awk '
    /^[[:space:]]*## / {
        heading=$0
        sub(/^[[:space:]]*##[[:space:]]*/, "", heading)
        next
    }
    /^[[:space:]]*bindsym / {
        line=$0
        sub(/^[[:space:]]*bindsym[[:space:]]+/, "", line)
        if (heading != "") {
            print heading ": " line
        } else {
            print line
        }
    }
' "$config" | less -R
