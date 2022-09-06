from libqtile.config import Group, Key, ScratchPad, DropDown
from libqtile.lazy import lazy
from libqtile.core.manager import Qtile
from libqtile import qtile
from settings.keys import keys
from settings.app_list import *

mod = "mod4"

groups = [
    Group(name = "1", label = ""),
    Group(name = "2", label = ""),
    Group(name = "3", label = ""),
    Group(name = "4", label = ""),
    Group(name = "5", label = ""),
    Group(name = "6", label = ""),
    Group(name = "7", label = ""),
    Group(name = "8", label = ""),
    Group(name = "9", label = ""),
    Group(name = "0", label = ""),
    ScratchPad(
        name = "dropdowns",
        dropdowns = [
            DropDown("term", terminal_dropdown, 
                height = 0.35, 
                width = 0.3, 
                x= 0.35, 
                y= 0.25,
                opacity = 1,
            ),
            DropDown("calcurse", calcurse, 
                height = 0.35, 
                width = 0.3, 
                x=0.35, 
                y=0.25,
                opacity = 1,
            ),
            DropDown("btop", btop, 
                height = 0.45, 
                width = 0.4, 
                x=0.30, 
                y=0.25,
                opacity = 1,
            ),
            DropDown("pacseek", pacseek, 
                height = 0.45, 
                width = 0.4, 
                x=0.30, 
                y=0.25,
                opacity = 1,
            ),
            DropDown("note_editor", note_editor, 
                height = 0.45, 
                width = 0.4, 
                x=0.30, 
                y=0.25,
                opacity = 1,
            ),
        ],
    )
]
## Go to group function for multi-monitor
def go_to_group(name: str) -> callable:
    def _inner(qtile: qtile) -> None:
        if len(qtile.screens) == 1:
            qtile.groups_map[name].cmd_toscreen()
            return

        if name in '12345':
            qtile.focus_screen(0)
            qtile.groups_map[name].cmd_toscreen()
        else:
            qtile.focus_screen(1)
            qtile.groups_map[name].cmd_toscreen()

    return _inner

## Keys for group handling ##
# Go to group
for group in groups:
    if group.name.isnumeric() == False:
        pass
    else:
        keys.append(
            Key([mod], group.name,
                lazy.function(go_to_group(group.name)),
                desc = format("Switch to group {group.name}")
            )
        )

# Move window to group and go to group
for group in groups:
    if group.name.isnumeric() == False:
        pass
    else:
        keys.append(
            Key([mod, "shift"], group.name,
                lazy.window.togroup(group.name),
                lazy.function(go_to_group(group.name)),
                desc = format("Move window and go to group {group.name}")
            )
        )

# Move window to group
for group in groups:
    if group.name.isnumeric() == False:
        pass
    else:
        keys.append(
            Key([mod, "shift", "control"], group.name,
                lazy.window.togroup(group.name),
                desc = format("Move window to group {group.name}")
            )
        )

# Toggle dropdown
keys.append(Key([mod], "minus", lazy.group["dropdowns"].dropdown_toggle("term")))
keys.append(Key([mod], "c", lazy.group["dropdowns"].dropdown_toggle("calcurse")))
keys.append(Key([mod], "b", lazy.group["dropdowns"].dropdown_toggle("btop")))
keys.append(Key([mod], "p", lazy.group["dropdowns"].dropdown_toggle("pacseek")))
keys.append(Key([mod], "equal", lazy.group["dropdowns"].dropdown_toggle("note_editor")))


