#!/bin/sh
# Read selected text aloud using kokoro TTS
KOKORO="$HOME/.local/bin/kokoro-tts"
MODEL="$HOME/.local/share/kokoro/kokoro-v1.0.onnx"
VOICES="$HOME/.local/share/kokoro/voices-v1.0.bin"
VOICE="am_michael"
TMPFILE="/tmp/tts-selection.wav"

text=$(wl-paste -p 2>/dev/null)
[ -z "$text" ] && notify-send -a "TTS" "TTS" "No text selected" && exit 1

notify-send -a "TTS" "TTS" "Reading aloud..."
echo "$text" | "$KOKORO" - "$TMPFILE" --voice "$VOICE" --model "$MODEL" --voices "$VOICES" 2>/dev/null && paplay "$TMPFILE"
