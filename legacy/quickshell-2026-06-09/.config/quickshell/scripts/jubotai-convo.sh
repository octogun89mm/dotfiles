#!/usr/bin/env bash
# JuBotAI-Convo quickshell module: status + toggle for the Convo Discord bot.
# Only manages bot.py — llama-server is shared and handled by jubotai.sh.

set -uo pipefail

BOT_DIR="$HOME/Projects/JuBotAI-Convo"
BOT_CMD_MATCH='JuBotAI-Convo/\.venv/bin/python -u bot\.py'
LLAMA_BIN=llama-server
LLAMA_PORT=3002
GHOSTTY_BOT_CLASS=jubotai-convo-bot

bot_pid()   { pgrep -f "$BOT_CMD_MATCH" | head -n1; }
llama_pid() { pgrep -x "$LLAMA_BIN"      | head -n1; }

status() {
    local b l class text tooltip
    b=$(bot_pid)
    l=$(llama_pid)

    if [[ -n "$b" && -n "$l" ]]; then
        class=jubotai-on
        text=ON
        tooltip="JuBotAI-Convo ON | bot pid $b | llama pid $l"
    elif [[ -n "$b" ]]; then
        class=jubotai-partial
        text=HALF
        tooltip="JuBotAI-Convo bot up but llama-server is off"
    else
        class=jubotai-off
        text=OFF
        tooltip="JuBotAI-Convo is off — click to start"
    fi

    jq --unbuffered --compact-output -n \
        --arg text "$text" \
        --arg class "$class" \
        --arg tooltip "$tooltip" \
        '{text: $text, alt: "󰭹", class: $class, tooltip: $tooltip}'
}

start() {
    ghostty --class="$GHOSTTY_BOT_CLASS" --title="jubotai-convo-bot" \
          --wait-after-command=true -e bash -lc "
              cd '$BOT_DIR' || exit 1
              for i in {1..60}; do
                  if ss -tln 2>/dev/null | grep -q ':${LLAMA_PORT}'; then break; fi
                  echo \"[jubotai-convo-toggle] waiting for llama-server on :${LLAMA_PORT} (\$i/60)\"
                  sleep 1
              done
              exec .venv/bin/python -u bot.py
          " >/dev/null 2>&1 &
    disown
}

stop() {
    local b
    b=$(bot_pid)
    [[ -n "$b" ]] && kill "$b" 2>/dev/null
    sleep 1
    b=$(bot_pid); [[ -n "$b" ]] && kill -9 "$b" 2>/dev/null
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch closewindow "class:^${GHOSTTY_BOT_CLASS}$" >/dev/null 2>&1
    fi
}

toggle() {
    if [[ -n "$(bot_pid)" ]]; then
        stop
    else
        start
    fi
}

case "${1:-status}" in
    toggle) toggle ;;
    start)  start ;;
    stop)   stop ;;
    *)      status ;;
esac
