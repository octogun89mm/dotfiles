#!/usr/bin/env bash
set -euo pipefail

SRC="$(pactl get-default-source 2>/dev/null || echo auto)"
TMP="$(mktemp --suffix=.conf)"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<EOF
[general]
framerate = 60
autosens = 1
bars = 12
sleep_timer = 0

[input]
method = pulse
source = ${SRC}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
channels = stereo
EOF

exec /usr/bin/cava -p "$TMP"
