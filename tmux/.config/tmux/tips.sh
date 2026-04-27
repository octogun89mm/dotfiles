#!/usr/bin/env bash

tips=(
  "C-a | — split pane horizontally"
  "C-a - — split pane vertically"
  "C-a c — new window in current path"
  "C-a , — rename current window"
  "C-a \$ — rename current session"
  "C-a d — detach from session"
  "C-a s — list sessions"
  "C-a w — list windows"
  "C-a x — kill current pane"
  "C-a & — kill current window"
  "C-a z — toggle pane zoom"
  "C-a Space — cycle pane layouts"
  "C-a { — swap pane with previous"
  "C-a } — swap pane with next"
  "C-a h/j/k/l — navigate panes vim-style"
  "C-a H/J/K/L — resize pane (repeatable)"
  "C-a </> — move window left/right"
  "C-a v — enter copy mode"
  "v then y — select and yank in copy mode"
  "C-a [ — enter copy/scroll mode"
  "C-a ] — paste buffer"
  "C-a ? — list all key bindings"
  "C-a t — show big clock"
  "C-a r — reload tmux config"
  "C-a : — open command prompt"
  "C-a 0..9 — jump to window N"
  "C-a n/p — next/previous window"
  "C-a l — last active window"
  "C-a ! — break pane into new window"
  "C-a q — show pane numbers"
)

cache=/tmp/tmux-tip-$USER
rotate=30

if [[ ! -f $cache ]] || (( $(date +%s) - $(stat -c %Y "$cache") >= rotate )); then
  printf '%s' "${tips[RANDOM % ${#tips[@]}]}" > "$cache"
fi

cat "$cache"
