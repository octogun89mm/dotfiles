#!/usr/bin/env bash

# Restart eww bar (replaces restart_waybar.sh)
eww close-all
eww kill
sleep 0.5
eww daemon &
sleep 1
eww open bar-primary
eww open bar-secondary
eww open bar-popup
