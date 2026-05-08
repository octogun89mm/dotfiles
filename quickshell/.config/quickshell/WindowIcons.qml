pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property string fallback: ""

  readonly property var entries: [
    [["firefox", "zen", "librewolf", "waterfox"], ""],
    [["kitty", "wezterm", "alacritty", "foot", "termite", "urxvt", "xterm", "konsole", "tilix", "terminal"], ""],
    [["nvim", "neovim"], ""],
    [["emacs"], ""],
    [["vim"], ""],
    [["jetbrains", "idea", "pycharm", "webstorm", "clion", "rubymine", "phpstorm", "goland", "rider", "datagrip"], ""],
    [["code", "vscodium", "codium", "cursor"], ""],
    [["sublime"], ""],
    [["zed"], ""],
    [["postman", "insomnia", "bruno", "hoppscotch"], ""],
    [["github", "gitkraken", "gitg", "lazygit"], ""],
    [["docker", "podman"], ""],
    [["virt-manager", "qemu", "virtualbox", "vmware"], "󰡹"],
    [["wireshark"], ""],
    [["discord", "vesktop", "webcord"], ""],
    [["slack"], "󰚑"],
    [["mattermost"], "󰊭"],
    [["telegram"], ""],
    [["whatsapp"], ""],
    [["signal"], "󰭹"],
    [["element", "matrix", "fractal"], "󰭩"],
    [["teams"], "󰊻"],
    [["zoom"], "󰕧"],
    [["thunderbird", "evolution", "mailspring", "geary", "betterbird"], "󰇮"],
    [["mail", "protonmail"], "󰺰"],
    [["spotify", "rhythmbox", "audacious", "clementine", "strawberry", "ncmpcpp", "cmus", "mpd"], ""],
    [["mpv", "vlc", "totem", "celluloid", "smplayer"], ""],
    [["obs-studio", "obs"], "󰕧"],
    [["steam", "lutris", "heroic", "minecraft", "prismlauncher"], ""],
    [["nautilus", "thunar", "dolphin", "pcmanfm", "nemo", "ranger", "yazi", "files"], ""],
    [["lf"], ""],
    [["obsidian", "notion", "logseq"], "󰎞"],
    [["joplin", "standardnotes", "simplenote"], "󰎞"],
    [["notes"], "󰎞"],
    [["anki"], "󰧑"],
    [["gimp", "krita", "darktable", "rawtherapee"], ""],
    [["inkscape"], ""],
    [["blender"], "󰂫"],
    [["figma"], ""],
    [["feh", "imv", "sxiv", "nsxiv", "qview", "gthumb"], ""],
    [["eog", "loupe", "geeqie"], ""],
    [["zathura", "evince", "okular", "xreader", "foliate", "mupdf"], ""],
    [["calibre"], ""],
    [["libreoffice-writer", "writer", "abiword"], "󰈙"],
    [["libreoffice-calc", "gnumeric"], "󰈛"],
    [["libreoffice-impress"], "󰈜"],
    [["libreoffice", "soffice", "onlyoffice"], ""],
    [["pavucontrol", "easyeffects", "helvum", "pulsemixer"], "󰓃"],
    [["bluetooth", "blueman", "blueberry"], "󰂯"],
    [["bitwarden", "keepassxc", "1password", "proton-pass"], "󰌾"],
    [["calcurse", "calendar", "gnome-calendar", "morgen"], ""],
    [["calculator", "qalculate", "gnome-calculator", "kcalc"], ""],
    [["htop", "btop", "bottom", "gotop", "glances"], ""],
    [["newsboat", "feedreader", "rss"], ""],
    [["torrent", "transmission", "qbittorrent", "deluge"], "󰆚"],
    [["telegram-desktop"], ""],
    [["scrcpy", "android-studio"], ""],
    [["edge"], ""],
    [["opera"], ""],
    [["safari"], ""],
    [["brave"], "󰕥"],
    [["helium"], "󰣣"],
    [["vivaldi"], "󰣩"],
    [["qutebrowser"], ""],
    [["chromium", "chrome"], ""]
  ]

  function iconFor(text) {
    if (!text) return fallback
    const key = String(text).toLowerCase()
    for (let i = 0; i < entries.length; i++) {
      const patterns = entries[i][0]
      for (let j = 0; j < patterns.length; j++) {
        if (key.includes(patterns[j])) return entries[i][1]
      }
    }
    return fallback
  }
}
