#!/usr/bin/env python3
"""Export Hyprland bindings as structured JSON for Quickshell."""

from __future__ import annotations

import json
import subprocess
import sys

MOD_BITS = {
    1: "SHIFT",
    4: "CTRL",
    8: "ALT",
    64: "SUPER",
}

MOD_ORDER = {
    "SUPER": 0,
    "SHIFT": 1,
    "CTRL": 2,
    "ALT": 3,
}

MODE_PRIORITY = {
    "SUPER": 0,
    "SUPER+SHIFT": 1,
    "SUPER+CTRL": 2,
    "SUPER+ALT": 3,
    "SUPER+CTRL+SHIFT": 4,
    "SUPER+ALT+SHIFT": 5,
    "SUPER+ALT+CTRL": 6,
    "SUPER+ALT+CTRL+SHIFT": 7,
    "PLAIN": 8,
}

KEY_ALIASES = {
    "grave": "GRAVE",
    "minus": "MINUS",
    "equal": "EQUAL",
    "backspace": "BACKSPACE",
    "tab": "TAB",
    "bracketleft": "BRACKETLEFT",
    "bracketright": "BRACKETRIGHT",
    "backslash": "BACKSLASH",
    "caps_lock": "CAPSLOCK",
    "semicolon": "SEMICOLON",
    "apostrophe": "APOSTROPHE",
    "return": "ENTER",
    "enter": "ENTER",
    "comma": "COMMA",
    "period": "PERIOD",
    "slash": "SLASH",
    "space": "SPACE",
    "spacebar": "SPACE",
    "left": "LEFT",
    "right": "RIGHT",
    "up": "UP",
    "down": "DOWN",
    "print": "PRINT",
    "printscreen": "PRINT",
    "insert": "INSERT",
    "delete": "DELETE",
    "home": "HOME",
    "end": "END",
    "pageup": "PAGEUP",
    "pgup": "PAGEUP",
    "prior": "PAGEUP",
    "pagedown": "PAGEDOWN",
    "pgdn": "PAGEDOWN",
    "next": "PAGEDOWN",
    "xf86audiomute": "XF86AUDIOMUTE",
    "xf86audioraisevolume": "XF86AUDIORAISEVOLUME",
    "xf86audiolowervolume": "XF86AUDIOLOWERVOLUME",
    "xf86audioplay": "XF86AUDIOPLAY",
    "xf86audioprev": "XF86AUDIOPREV",
    "xf86audionext": "XF86AUDIONEXT",
    "xf86monbrightnessup": "XF86MONBRIGHTNESSUP",
    "xf86monbrightnessdown": "XF86MONBRIGHTNESSDOWN",
    "mouse:272": "MOUSE_LEFT",
    "mouse:273": "MOUSE_RIGHT",
    "mouse:274": "MOUSE_MIDDLE",
}


def classify_category(desc: str, dispatcher: str, arg: str, modifiers: list[str], normalized_key: str) -> str:
    dispatcher_name = (dispatcher or "").lower()
    arg_text = (arg or "").lower()
    text = " ".join(
        part.lower()
        for part in [desc, dispatcher_name, arg_text]
        if part
    )

    if normalized_key.startswith("MOUSE_"):
        return "mouse"

    if normalized_key in {"SUPER", "SHIFT", "CTRL", "ALT"}:
        return "modifier"

    if dispatcher_name in {"workspace", "movetoworkspace", "movetoworkspacesilent", "togglespecialworkspace"}:
        return "workspace"

    if dispatcher_name in {"layoutmsg", "movefocus", "moveintogroup", "resizeactive", "submap"}:
        return "layout"

    if dispatcher_name in {"killactive", "fullscreen", "togglefloating", "pin", "centerwindow", "movewindow", "moveactive", "togglegroup", "moveoutofgroup"}:
        return "window"

    if dispatcher_name == "exec" and any(token in text for token in ["terminal", "browser", "launcher", "menu", "clipboard", "neovim", "emacs", "file manager", "powermenu", "tools"]):
        return "launcher"

    if dispatcher_name in {"sendshortcut"}:
        return "system"

    if "workspace" in text or "scratchpad" in text or "specialworkspace" in text:
        return "workspace"

    if any(token in text for token in ["focus", "layout", "resize", "swap", "move into group", "roll ", "fit ", "group", "orientation", "cycle", "submap"]):
        return "layout"

    if any(token in text for token in ["terminal", "browser", "launcher", "menu", "clipboard", "neovim", "emacs", "file manager", "powermenu", "tools"]):
        return "launcher"

    if any(token in text for token in ["kill", "fullscreen", "floating", "pin", "center window", "movewindow", "moveactive", "toggle group", "window"]):
        return "window"

    if any(token in text for token in ["volume", "audio", "mute", "sink", "source", "vpn", "idle", "llm", "tts", "discord"]):
        return "system"

    if not modifiers:
        return "plain"

    return "other"


def get_binds() -> list[dict]:
    result = subprocess.run(
        ["hyprctl", "binds", "-j"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "hyprctl binds failed")

    return json.loads(result.stdout)


def normalize_modifiers(modmask: int) -> list[str]:
    modifiers = [name for bit, name in MOD_BITS.items() if modmask & bit]
    return sorted(modifiers, key=lambda name: MOD_ORDER.get(name, 99))


def normalize_key(key: str) -> str:
    if not key:
        return ""

    lowered = key.strip().lower()
    if lowered in KEY_ALIASES:
        return KEY_ALIASES[lowered]

    if len(lowered) == 1:
        return lowered.upper()

    return lowered.upper()


def build_combo(modifiers: list[str], key: str) -> str:
    parts = modifiers[:]
    if key:
        parts.append(key)
    return " + ".join(parts)


def mode_name(modifiers: list[str]) -> str:
    return "+".join(modifiers) if modifiers else "PLAIN"


def mode_sort_key(name: str) -> tuple[int, str]:
    return (MODE_PRIORITY.get(name, 100), name)


def parse_bind(raw_bind: dict) -> dict:
    modifiers = normalize_modifiers(raw_bind.get("modmask", 0))
    raw_key = raw_bind.get("key", "")
    normalized_key = normalize_key(raw_key)
    combo_key = normalized_key or raw_key

    desc = raw_bind.get("description", "")
    dispatcher = raw_bind.get("dispatcher", "")
    arg = raw_bind.get("arg", "")
    submap = raw_bind.get("submap", "") or "global"

    if not desc:
        desc = f"{dispatcher} {arg}".strip() if arg else dispatcher

    flags = []
    if raw_bind.get("repeat", False):
        flags.append("repeat")
    if raw_bind.get("mouse", False):
        flags.append("mouse")

    return {
        "submap": submap,
        "combo": build_combo(modifiers, combo_key),
        "desc": desc,
        "flags": flags,
        "modifiers": modifiers,
        "modifierMode": mode_name(modifiers),
        "key": raw_key,
        "normalizedKey": normalized_key,
        "dispatcher": dispatcher,
        "arg": arg,
        "mouse": bool(raw_bind.get("mouse", False)),
        "repeat": bool(raw_bind.get("repeat", False)),
        "category": classify_category(desc, dispatcher, arg, modifiers, normalized_key),
    }


def main() -> int:
    try:
        binds = [parse_bind(bind) for bind in get_binds()]
    except Exception as exc:  # pragma: no cover - simple CLI failure path
        print(json.dumps({"error": str(exc)}))
        return 1

    modifier_modes = sorted({bind["modifierMode"] for bind in binds}, key=mode_sort_key)
    submaps = sorted(
        {bind["submap"] for bind in binds},
        key=lambda name: (name != "global", name),
    )

    print(
        json.dumps(
            {
                "binds": binds,
                "modifierModes": modifier_modes,
                "submaps": submaps,
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
