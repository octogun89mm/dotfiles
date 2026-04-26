#!/usr/bin/env bash
# Capture mono PCM from default sink monitor, emit one envelope frame per chunk:
#   <signed_mean>;<peak_amplitude>   (both in -1..1 range)
# Frame rate ≈ 120Hz so QML can render a smooth oscilloscope.
set -euo pipefail

SINK="$(pactl get-default-sink 2>/dev/null || true)"
if [[ -z "$SINK" ]]; then
    echo "waveform.sh: no default sink" >&2
    exit 1
fi

exec parec --format=s16le --rate=8000 --channels=1 -d "${SINK}.monitor" --raw \
  | python3 -u -c '
import sys, struct
CHUNK = 67  # ~120Hz at 8000Hz
while True:
    data = sys.stdin.buffer.read(CHUNK * 2)
    if not data:
        break
    n = len(data) // 2
    if n == 0:
        continue
    samples = struct.unpack(f"<{n}h", data)
    avg = sum(samples) / n / 32768.0
    peak = max(abs(s) for s in samples) / 32768.0
    print(f"{avg:.4f};{peak:.4f}", flush=True)
'
