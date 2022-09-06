import os
import subprocess
from libqtile import hook, layout 
from libqtile.config import Match
from libqtile.core.manager import Qtile
from settings.colors import colors 
from settings.keys import keys
from settings.groups import groups
from settings.layouts import layouts
from settings.screens import screens 
from settings.mouse import mouse 
import scripts.dynamic_margin_resize

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~/.config/qtile/autostart.sh')
    subprocess.Popen([home])

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False 
auto_fullscreen = False
focus_on_window_activation = "never"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"

floating_layout = layout.Floating(
        float_rules=[
            *layout.Floating.default_float_rules,
            Match(wm_class="confirmreset"),
            Match(wm_class="makebranch"),
            Match(wm_class="maketag"),
            Match(wm_class="ssh-askpass"),
            Match(title="branchdialog"),
            Match(title="pinentry"),
            Match(wm_class="pavucontrol"),
            Match(wm_class="VirtualBox Machine"),
        ],
        border_focus = colors[2], 
        border_normal = colors[8],
        border_width = 3,
)
