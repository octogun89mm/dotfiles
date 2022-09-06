from libqtile import layout
from libqtile.config import Key
from settings.keys import keys
from libqtile.lazy import lazy

mod = "mod4"

@lazy.layout.function
def change_layout_gap(layout, adjustment):
    layout.margin = layout.margin + adjustment
    layout.cmd_reset()

@lazy.layout.function
def reset_layout_gap(layout):
    layout.margin = 10 
    layout.cmd_reset()

keys.append(Key([mod], 'g', change_layout_gap(adjustment =+ 5), desc = 'Increase gap by 5'))
keys.append(Key([mod, "shift"], 'g', change_layout_gap(adjustment =- 5), desc = 'Decrease gap by 5'))
keys.append(Key([mod, "shift", "control"], 'g', reset_layout_gap(), desc = 'Resets gap'))
