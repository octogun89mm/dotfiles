import subprocess
from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.backend.wayland.inputs import InputConfig
from qtile_extras import widget as extra_widget
from colors import colors

mod = "mod4"
terminal = "ghostty"
webbrowser = "helium-browser"

@hook.subscribe.startup_once
def autostart():
    subprocess.Popen(["/usr/lib/polkit-kde-authentication-agent-1"])
    subprocess.Popen(["swww-daemon"])
    subprocess.Popen(["waypaper", "--restore"])
    subprocess.Popen(["wl-paste", "--watch", "cliphist", "store"])

def get_governor():
    try:
        with open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor") as f:
            gov = f.read().strip()
        return "PERF" if gov == "performance" else "PWR"
    except:
        return "?"

def get_tailscale():
    try:
        res = subprocess.check_output(["tailscale", "status", "--json"], stderr=subprocess.DEVNULL)
        import json
        data = json.loads(res)
        if data.get("BackendState") == "Running":
            return "ON"
        return "OFF"
    except:
        return "OFF"

keys = [
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(), desc="Toggle between split and unsplit sides of stack",),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.spawn(webbrowser), desc="Launch Web Browser"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window",),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Spawn Rofi drun mode"),
    Key([mod], "s", lazy.spawn("~/.dotfiles/rust-tools/target/release/rofi-tools"), desc="Spawn Rofi tools"),
    Key([mod], "b", lazy.spawn("~/.dotfiles/rust-tools/target/release/rofi-apps"), desc="Spawn Rofi apps"),
    Key([mod], "z", lazy.screen.prev_group(skip_empty=True)),
    Key([mod], "x", lazy.screen.next_group(skip_empty=True)),
    Key([mod, "shift"], "z", lazy.screen.prev_group(skip_empty=False)),
    Key([mod, "shift"], "x", lazy.screen.next_group(skip_empty=False)),
    Key([mod, "shift"], "b", lazy.function(lambda q: q.hide_show_bar("bottom"))),

    # System controls
    Key([], "F13", lazy.spawn("~/.config/waybar/scripts/idle-inhibit.sh toggle")),
    Key([], "F14", lazy.spawn("~/.dotfiles/rust-tools/target/release/hypridle-suspend toggle")),
    # Discord controls (global shortcuts)
    Key([], "F21", lazy.spawn("wtype -M ctrl -M shift m")),
    Key([], "F20", lazy.spawn("wtype -M ctrl -M shift d")),
]

for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


groups = []
for i in "1256":
    groups.append(Group(i))
for i in "34":
    groups.append(Group(i, layouts=[
        layout.MonadTall(
            border_width=2,
            border_focus=colors["c2"],
            border_normal=colors["c0"],
            margin=10,
            single_border_width=2,
            single_margin=10,
            new_client_position="before_current",
        ),
        layout.Max(),
    ]))

for i in groups:
    keys.extend(
        [
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
        ]
    )

layouts = [
    layout.MonadTall(
        border_width=2,
        border_focus=colors["c2"],
        border_normal=colors["c0"],
        margin=10,
        single_border_width=0,
        single_margin=0,
        max_ratio=0.75,
        min_ratio=0.25,
        new_client_position="before_current",
    ),
    layout.Max(),
]

widget_defaults = dict(
    font="Iosevka",
    fontsize=12,
    padding=0,
    foreground=colors["fg"]
)
extension_defaults = widget_defaults.copy()

def init_widgets_list():
    widgets_list = [
        widget.Spacer(
            length=6,
        ),
        widget.GroupBox(
            highlight_method="text",
            active=colors["fg"],
            this_current_screen_border=colors["c2"],
            fmt="[ {} ]",
            hide_unused=True,
            rounded=False,
            spacing=0,
            margin_x=0,
            padding_x=0,
        ),
        widget.Spacer(),
        widget.Clock(
            format="%a-%d-%m-%y",
            fmt="[ {} ]",
        ),
        widget.Clock(
            format="%I:%M%p",
            fmt="[ {} ]",
        ),
        widget.Spacer(
            length=6,
        ),
    ]
    return widgets_list

def init_secondary_widgets_list():
    widgets_list = [
        widget.Clock(
            format="%I:%M%p",
            fmt="[ {} ]",
        ),
        widget.Spacer(),
        widget.GroupBox(
            highlight_method="text",
            active=colors["fg"],
            this_current_screen_border=colors["c2"],
            fmt="[ {} ]",
            hide_unused=True,
            rounded=False,
            spacing=0,
            margin_x=0,
            padding_x=0,
        ),
    ]
    return widgets_list

def init_bottom_bar():
    return bar.Bar(
        [
            widget.TextBox(
                fmt=" ",
            ),
            widget.GenPollText(
                func=get_governor,
                update_interval=5,
                fmt="[ GOV: {} ]",
                mouse_callbacks={'Button1': lambda: qtile.spawn("pkexec sh -c 'CURRENT=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor); if [ \"$CURRENT\" = \"powersave\" ]; then echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; else echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; fi'")}
            ),
            widget.GenPollText(
                func=get_tailscale,
                update_interval=10,
                fmt="[ TS: {} ]",
                mouse_callbacks={'Button1': lambda: qtile.spawn("tailscale up" if get_tailscale() == "OFF" else "tailscale down")}
            ),
            widget.Spacer(
                length=bar.STRETCH,
            ),
            widget.TextBox(
                fmt="[ MEM: "
            ),
            widget.Memory(
                format="{MemUsed:>4.1f}G / {MemTotal:.1f}G ]",
                measure_mem="G",
                update_interval=2,
            ),
            widget.TextBox(
                fmt="[ CPU: "
            ),
            widget.CPU(
                format="{load_percent:>4}% ]",
                update_interval=2,
            ),
            widget.TextBox(
                fmt="[ NET: "
            ),
            widget.Net(
                format="{down:>5.1f}⇂ {up:>5.1f}↾ ]",
                interface="wlan1",
                prefix="k",
            ),
            widget.TextBox(
                fmt="[ SSD: "
            ),
            widget.DF(
                visible_on_warn=False,
                format="{uf}G / {s}G ]",
            ),
            widget.Spacer(
                length=bar.STRETCH,
            ),
            extra_widget.StatusNotifier(),
            widget.TextBox(
                fmt=" ",
            ),
        ],
        size=21,
        background=colors["bg"],
    )

screens = [
    Screen(
        top=bar.Bar(init_widgets_list(), size=24, background=colors["bg"]),
        bottom=init_bottom_bar(),
    ),
    Screen(
        top=bar.Bar(init_secondary_widgets_list(), size=24, background=colors["bg"]),
    ),
    Screen(
        top=bar.Bar(init_secondary_widgets_list(), size=24, background=colors["bg"]),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = True
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True

auto_minimize = True

wl_input_rules = {
    "type:keyboard": InputConfig(
        kb_options="caps:escape",
    )
}

wl_xcursor_theme = "S1mpleDark"
wl_xcursor_size = 24

wmname = "LG3D"
