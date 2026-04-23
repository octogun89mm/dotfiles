#!/usr/bin/env python3
"""Block resume until Enter is pressed.

Grabs every keyboard exclusively, keeps dpms off, drains key events until
KEY_ENTER is pressed. Any other key is silently swallowed.
"""
import glob
import os
import select
import subprocess
import sys

import evdev
from evdev import ecodes


def is_keyboard(dev):
    caps = dev.capabilities().get(ecodes.EV_KEY, [])
    return ecodes.KEY_ENTER in caps and ecodes.KEY_A in caps


def main():
    paths = glob.glob("/dev/input/by-id/*-event-kbd")
    if not paths:
        paths = [p for p in glob.glob("/dev/input/event*")]

    devices = []
    for p in paths:
        try:
            d = evdev.InputDevice(p)
            if is_keyboard(d):
                d.grab()
                devices.append(d)
        except (OSError, PermissionError):
            continue

    if not devices:
        subprocess.run(["hyprctl", "dispatch", "dpms", "on"])
        sys.exit(0)

    subprocess.run(["hyprctl", "dispatch", "dpms", "off"])

    fd_map = {d.fd: d for d in devices}
    try:
        while True:
            r, _, _ = select.select(fd_map, [], [])
            for fd in r:
                for ev in fd_map[fd].read():
                    if (
                        ev.type == ecodes.EV_KEY
                        and ev.code == ecodes.KEY_ENTER
                        and ev.value == 1
                    ):
                        return
    finally:
        for d in devices:
            try:
                d.ungrab()
            except OSError:
                pass
        subprocess.run(["hyprctl", "dispatch", "dpms", "on"])


if __name__ == "__main__":
    main()
