from libqtile import layout
from libqtile.config import Match
from settings.colors import colors

default_margin = 10
default_border_width = 3
default_border_focus = colors[2]
default_border_normal = colors[8]

layouts = [
    layout.MonadTall(
        margin = default_margin,
        border_width = default_border_width,
        border_focus = default_border_focus,
        border_normal = default_border_normal,
        new_client_position = 'after_current',
        ratio = 0.5,
        align = 1,
    ),

    layout.MonadWide(
        margin = default_margin,
        border_width = default_border_width,
        border_focus = default_border_focus,
        border_normal = default_border_normal,
        new_client_position = 'after_current',
        ratio = 0.5,
    ),

    layout.Max(
    ),

    layout.RatioTile(
        margin = default_margin,
        border_width = default_border_width,
        border_focus = default_border_focus,
        border_normal = default_border_normal,
        fancy = True,
    ),
    
    layout.Spiral(
        margin = default_margin,
        border_width = default_border_width,
        border_focus = default_border_focus,
        border_normal = default_border_normal
    ),
]


