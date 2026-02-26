#!/usr/bin/env bash

# Toggle eww bar popup visibility
eww update popup_visible=$([ "$(eww get popup_visible)" = "true" ] && echo "false" || echo "true")
