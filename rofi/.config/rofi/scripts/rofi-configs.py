#!/usr/bin/env python3

import os
import subprocess

configs = {
    "Hyprland": os.path.expanduser("~/.config/hypr/hyprland.conf"),
    "Waybar": os.path.expanduser("~/.config/waybar/config.jsonc"),
    "Neovim": os.path.expanduser("~/.config/nvim/init.lua"),
}

menu = "\n".join(configs.keys())

result = subprocess.run(
    ["rofi", "-dmenu", "-p", "Config"],
    input = menu,
    text = True,
    capture_output = True,
)

choice = result.stdout.strip()
if not choice:
    exit(0)

path = configs.get(choice)
if not path:
    exit(1)

terminal = os.environ.get("TERMINAL", "kitty")
editor = os.environ.get("EDITOR", "nvim")

cmd = f'exec "{editor}" "{path}"'

subprocess.Popen(
    [terminal, "--", "sh", "-c", cmd],
    stdout = subprocess.DEVNULL,
    stderr = subprocess.DEVNULL,
)
