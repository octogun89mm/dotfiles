from libqtile.config import Key
from libqtile.lazy import lazy
from settings.app_list import * 

mod = "mod4"

def notif_generator(string):
    qtile_icon = "/home/julien/.icons/Qtile/q_logo_transparent_bg.svg"
    space = " "
    title = "Qtile"
    return "notify-send -i {}".format(qtile_icon) + space + "'{}'".format(title) + space + "'{}'".format(string)

keys = [
    ## Move focus
    Key([mod], "h",
        lazy.layout.left(),
        desc = "Move focus to left"
    ),

    Key([mod], "l",
        lazy.layout.right(),
        desc = "Move focus to right"
    ),
    
    Key([mod], "j",
        lazy.layout.down(),
        desc = "Move focus down"
    ),
    
    Key([mod], "k",
        lazy.layout.up(),
        desc = "Move focus up"
    ),
    ## Move focus to screen
    Key([mod], 'period',
        lazy.next_screen(),
        desc = 'Focus next monitor'
    ),
    ## Generate theme from wallpaper    
    Key([mod, "shift"], "r",
        lazy.spawn(change_theme_random),
        desc = "Set theme on terminal, qtile, etc. based on the wallpaper"
    ),
    ## Toggles
    Key([mod], "f",
        lazy.window.toggle_fullscreen(),
        lazy.spawn(notif_generator('Window fullscreen toggled')),
        desc = "Toggle focused window fullscreen"
    ),
        
    Key([mod, "shift"], "f",
        lazy.window.toggle_floating(),
        lazy.spawn(notif_generator('Window floating toggled')),
        desc = "Toggle focused window floating"
    ),
    ## Move window/resize and layout handling 
    Key([mod, "shift"], "h",
        lazy.layout.swap_left()
    ),
    
    Key([mod, "shift"], "l",
        lazy.layout.swap_right()
    ),
    
    Key([mod, "shift"], "j",
        lazy.layout.shuffle_down()
    ),
    
    Key([mod, "shift"], "k",
        lazy.layout.shuffle_up()
    ),
    
    Key([mod, "shift"], "i",
        lazy.layout.grow()
    ),
    
    Key([mod, "shift"], "o",
        lazy.layout.shrink()
    ),
    
    Key([mod, "shift"], "n",
        lazy.layout.reset(),
        lazy.spawn(notif_generator('Layout reseted')),
    ),
    
    Key([mod, "shift"], "m",
        lazy.layout.maximize()
    ),
    
    Key([mod, "shift"], "space",
        lazy.layout.flip(),
        lazy.spawn(notif_generator('Layout flipped')),
    ),
    ## Switch layouts 
    Key([mod], "Tab",
        lazy.next_layout(),
        desc = "Toggle between layouts"
    ),
    ## Kill window
    Key([mod], "q",
        lazy.window.kill(),
        desc = "Kill focused window"
    ),
    ## Reload config
    Key([mod, "control"], "r",
        lazy.reload_config(),
        lazy.spawn(notif_generator('Config reloaded')),
        desc = "Reload the config"
    ),
    ## Shutdown Qtile
    Key([mod, "control"], "q",
        lazy.shutdown(),
        desc = "Shutdown Qtile"
    ),
    ## Spawn menus
    Key([mod], "s",
        lazy.spawn(screenshot_menu),
        desc = "Spawn a command using Rofi"
    ),
    
    Key([mod], "d",
        lazy.spawn(app_launcher),
        desc = "Spawn a command using Rofi"
    ),
    
    Key([mod, "shift"], "d",
        lazy.spawn(sidebar_app_launcher),
        desc = "Spawn a GUI app using Rofi"
    ),
    
    Key([mod], "x",
        lazy.spawn(power_menu),
        desc = "Spawn power menu"
    ),
    
    Key([mod], "z",
        lazy.spawn(display_power_menu),
        desc = "Spawn display power menu"
    ),
    ## Spawn Apps
    Key([mod], "Return",
        lazy.spawn(terminal),
        desc = "Launch terminal"
    ),

    Key([mod], "w",
        lazy.spawn(web_browser),
        desc = "Spawn Firefox"
    ),
    
    Key([mod], "e",
        lazy.spawn(file_manager_gui),
        desc = "Spawn GUI file manager"
    ),
    
    Key([mod], "v",
        lazy.spawn("emacsclient -c -a emacs"),
        desc = "Spawn Emacs"
    ),
    
    Key([mod], "a",
        lazy.spawn(terminal_editor),
        desc = "Spawn terminal editor"
    ),
    
    Key([mod], "r",
        lazy.spawn(ranger),
        desc = "Spawn Ranger (TUI File Manager)"
    ),
    
    ## Switch keyboard layout
    Key([mod, "control"], "s",
        lazy.widget["keyboardlayout"].next_keyboard(),
        desc="Next keyboard layout"
    ),
    ## Multimedia control (volume controlled by pa-applet) 
    Key([], "XF86AudioPlay",
        lazy.spawn("playerctl play-pause"),
        desc = "Play/Pause current playing media"
    ),
    
    Key([], "XF86AudioPrev",
        lazy.spawn("playerctl previous"),
        desc = "Previous current playing media"
    ),
    
    Key([], "XF86AudioNext",
        lazy.spawn("playerctl next"),
        desc = "Previous current playing media"
    ),
]
