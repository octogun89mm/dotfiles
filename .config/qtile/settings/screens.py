from libqtile.core.manager import Qtile
from libqtile import bar, qtile, widget
from libqtile.config import Screen 
from libqtile.lazy import lazy
from settings.colors import colors
from settings.app_list import *
import subprocess


#######################################
## DEFAULTS                          ##
#######################################

# Default fonts appearance
regular_font = "Input Mono, Bold"
bold_font = "Input Mono, Medium"
black_font = "Input Mono, Black"

# Default icon appearance
icon_font = "Font Awesome 6 Free Solid, Solid"
icon_font_size = 16
icon_color = colors[4]
icon_spacer = widget.Spacer(length = 5)

# Default widget appearance
widget_defaults = dict(
    font = regular_font,
    fontsize = 14,
    padding = 0,
    background = None,
    foreground = colors[7],
)

# Default extension appearance (copy of the widget appearance)
extension_defaults = widget_defaults.copy()

# Default separator appearance
separator = widget.Sep(
    foreground = colors[8],
    linewidth = 3,
    padding = 20,
    size_percent = 50,
)

# Default widget spacer length
widget_label_spacer = widget.Spacer(
    length = 8,
)


#######################################
## INITIALIZATION                    ##
#######################################

# Init weather widget
weather_widget = widget.OpenWeather(
    app_key = "7834197c2338888258f8cb94ae14ef49",
    cityid = "2643743",
    format = '<span font_desc="Font Awesome 6 Free Solid, Solid">{icon}</span> {main_feels_like:.1f}°{units_temperature}',
    weather_symbols = {
       "Unknown": "",
        "01d": "",
        "01n": "",
        "02d": "",
        "02n": "",
        "03d": "",
        "03n": "",
        "04d": "",
        "04n": "",
        "09d": "",
        "09n": "",
        "10d": "",
        "10n": "",
        "11d": "",
        "11n": "",
        "13d": "",
        "13n": "",
        "50d": "",
        "50n": "",
    },
    **widget_defaults,
)


#######################################
## USER FUNCTIONS                    ##
#######################################

### UTILITY FUNCTIONS ###

# Parsing function for windows titles
def parse_title(title):
    title_list = ["Firefox", "Vim", "vim", "nvim"]
    for string in title_list:
        if string in title:
            title = string
        else:
            title = title

#######################################
## DEFAULTS                          ##
#######################################

# Default fonts appearance
regular_font = "Input Mono, Bold"
bold_font = "Input Mono, Medium"
black_font = "Input Mono, Black"

# Default icon appearance
icon_font = "Font Awesome 6 Free Solid, Solid"
icon_font_size = 16
icon_color = colors[4]
icon_spacer = widget.Spacer(length = 5)

# Default widget appearance
widget_defaults = dict(
    font = regular_font,
    fontsize = 14,
    padding = 0,
    background = None,
    foreground = colors[7],
)

# Default extension appearance (copy of the widget appearance)
extension_defaults = widget_defaults.copy()

# Default separator appearance
separator = widget.Sep(
    foreground = colors[8],
    linewidth = 3,
    padding = 20,
    size_percent = 60,
)

# Default widget spacer length
widget_label_spacer = widget.Spacer(
    length = 8,
)


#######################################
## USER FUNCTIONS                    ##
#######################################

### UTILITY FUNCTIONS ###

# Parsing function for windows titles
def parse_title(title):
    title_list = ["Firefox", "Vim", "vim", "nvim"]
    for string in title_list:
        if string in title:
            title = string
        else:
            title = title
    return title

### MOUSE CALLBACKS ###

# Opens Rofi as start menu (Like windows)
def open_rofi_sidebar():
    qtile.cmd_spawn(sidebar_app_launcher)


#######################################
## INITIALISATION                    ##
#######################################

# Init weather widget
weather_widget = widget.OpenWeather(
    app_key = "2966b50b920faa427f8b92cceedb1068",
    cityid = "5978353",
    format = '<span font_desc="Font Awesome 6 Free Solid, Solid">{icon}</span> {main_feels_like:.1f}°{units_temperature}',
    weather_symbols = {
       "Unknown": "",
        "01d": "",
        "01n": "",
        "02d": "",
        "02n": "",
        "03d": "",
        "03n": "",
        "04d": "",
        "04n": "",
        "09d": "",
        "09n": "",
        "10d": "",
        "10n": "",
        "11d": "",
        "11n": "",
        "13d": "",
        "13n": "",
        "50d": "",
        "50n": "",
    },
    **widget_defaults,
)


#######################################
## SCREENS                           ##
#######################################

screens = [
    Screen(
        top = bar.Bar([
            widget.Spacer(length = 15),

            widget.TextBox(
                text = "",
                font = icon_font,
                fontsize = 25,
                foreground = colors[2],
                padding = 0,
                mouse_callbacks = {'Button1': open_rofi_sidebar},
                ),

            separator,

            widget.CurrentLayoutIcon(
                scale = 0.4,
                padding = 0,
                ),
            
            widget.CurrentLayout(
                font = bold_font,
                fontsize = 14,
                foreground = colors[7],
                padding = 0,
                fmt = "{:<10}"
                ),

            separator,

            widget.TaskList(
                foreground = colors[0],
                border = colors[2],
                focus_foreground = colors[0], 
                unfocused_border = colors[8],
                font = bold_font,
                fontsize = 14,
                highlight_method = "block",
                padding_y = 3,
                padding_x = 6,
                margin_y = 4,
                spacing = 10,
                rounded = False,
                max_title_width = 300,
                title_width_method = "uniform", 
                icon_size = 0,
            ),
            
            widget.Spacer(),

            widget.GroupBox(
                fontsize = 18,
                font = icon_font,
                highlight_method = "block",
                block_highlight_text_color = colors[0],
                active = colors[7],
                inactive = colors[8],
                this_current_screen_border = colors[2],
                other_current_screen_border = colors[2],
                this_screen_border = colors[6],
                other_screen_border = colors[6],
                urgent_alert_method = "line",
                urgent_text = colors[7],
                urgent_border = colors[8],
                padding_y = 3,
                padding_x = 5,
                rounded = False,
                disable_drag = True,
                borderwidth = 3,
                ),

            widget.Spacer(),
            
            widget.TextBox(
                text = "",
                foreground = icon_color,
                font = icon_font,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.Net(
                format = '{down} <span font_desc="Font Awesome 6 Free Solid, Solid" size="small"></span> {up}',
                **widget_defaults,
                ),
 
            separator,
            
            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.CPU(
                format = "{load_percent:>4}% {freq_current}GHz",
                **widget_defaults,
                ), 

            separator,
            
            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),
            
            widget_label_spacer,

            widget.Memory(
                format = '{MemUsed: .1f}{mm} <span font_desc="Font Awesome 6 Free Solid, Solid" size="small"></span>{MemTotal: .0f}{mm}', 
                measure_mem = "G",
                **widget_defaults,
                ),

            separator,

            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),
            
            widget_label_spacer,

            widget.DF(
                format = '{f}{m} <span font_desc="Font Awesome 6 Free Solid, Solid" size="small"></span> {s}{m}',

                visible_on_warn = False,
                **widget_defaults
                ),

            separator,

            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.NvidiaSensors(
                format = "{temp}°C {fan_speed} {perf}",
                gpu_bus_id = "01:00.0",
                **widget_defaults,
                ),

            separator,

            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.KeyboardLayout(
                configured_keyboards = ["us", "ca multix"],
                display_map = {"us":"US", "ca multix":"CA"},
                **widget_defaults,
                ),

            separator,

            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.GenPollText(
                update_interval = 30,
                func = lambda: subprocess.check_output("/home/julien/.config/qtile/scripts/vpn_status.sh").decode("utf-8"),
                **widget_defaults,
                ),
                
            separator,

            widget.TextBox(
                text = "",
                font = icon_font,
                foreground = icon_color,
                fontsize = icon_font_size,
                ),

            widget_label_spacer,

            widget.CheckUpdates(
                custom_command = "yay -Qu",
                no_update_string = "No update",
                display_format = "Updates {updates}",
                colour_have_updates = colors[3],
                colour_no_updates = colors[7],
                update_interval = 1800,
                **widget_defaults,
                ),

            widget.Spacer(length = 30),

            weather_widget,
            
            separator,

            widget.Clock(
                format = "%a-%d-%b-%Y",    
                **widget_defaults,
                ),

            separator,

            widget.Clock(
                font = black_font,
                fontsize = 20,
                padding = 0,
                foreground = colors[7]
                ),
 
            widget.Spacer(length = 15),
        ],
    size = 34,
    background = colors[0],
        ),
    )
]  

