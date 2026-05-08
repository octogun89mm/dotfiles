#!/usr/bin/env bash
set -euo pipefail

json_string() {
  jq -Rn --arg value "$1" '$value'
}

print_status() {
  local loaded="$1"
  local tooltip="$2"

  printf '{"loaded":%s,"icon":"󰧑","tooltip":%s}\n' \
    "$loaded" \
    "$(json_string "$tooltip")"
}

llama_models() {
  pgrep -af '[l]lama-server' 2>/dev/null \
    | while IFS= read -r line; do
        alias_name="$(printf '%s\n' "$line" | sed -n 's/.*--alias[ =]\([^ ]*\).*/\1/p')"
        if [[ -n "$alias_name" ]]; then
          printf '%s\n' "$alias_name"
          continue
        fi

        model_path="$(printf '%s\n' "$line" | sed -n 's/.* -m \([^ ]*\).*/\1/p')"
        if [[ -n "$model_path" ]]; then
          basename "$model_path"
        fi
      done \
    | paste -sd ', ' -
}

llama_loaded="$(llama_models || true)"
if [[ -n "$llama_loaded" ]]; then
  print_status true "llama.cpp loaded: $llama_loaded"
  exit 0
fi

print_status false "No llama.cpp model loaded"
