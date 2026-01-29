#!/usr/bin/env bash

killall waybar
sleep 0.5
waybar -c /home/juju/.config/waybar/config-hyprland-top.jsonc -s /home/juju/.config/waybar/style-hyprland-top.css &
waybar -c /home/juju/.config/waybar/config-hyprland-bottom.jsonc -s /home/juju/.config/waybar/style-hyprland-bottom.css &
