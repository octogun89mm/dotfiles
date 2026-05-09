pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property string fallback: ""

  readonly property string discordSvg: "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><path fill=\"currentColor\" d=\"M19.27 5.33C17.94 4.71 16.5 4.26 15 4a.1.1 0 0 0-.07.03c-.18.33-.39.76-.53 1.09a16.1 16.1 0 0 0-4.8 0c-.14-.34-.35-.76-.54-1.09c-.01-.02-.04-.03-.07-.03c-1.5.26-2.93.71-4.27 1.33c-.01 0-.02.01-.03.02c-2.72 4.07-3.47 8.03-3.1 11.95c0 .02.01.04.03.05c1.8 1.32 3.53 2.12 5.24 2.65c.03.01.06 0 .07-.02c.4-.55.76-1.13 1.07-1.74c.02-.04 0-.08-.04-.09c-.57-.22-1.11-.48-1.64-.78c-.04-.02-.04-.08-.01-.11c.11-.08.22-.17.33-.25c.02-.02.05-.02.07-.01c3.44 1.57 7.15 1.57 10.55 0c.02-.01.05-.01.07.01c.11.09.22.17.33.26c.04.03.04.09-.01.11c-.52.31-1.07.56-1.64.78c-.04.01-.05.06-.04.09c.32.61.68 1.19 1.07 1.74c.03.01.06.02.09.01c1.72-.53 3.45-1.33 5.25-2.65c.02-.01.03-.03.03-.05c.44-4.53-.73-8.46-3.1-11.95c-.01-.01-.02-.02-.04-.02M8.52 14.91c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.84 2.12-1.89 2.12m6.97 0c-1.03 0-1.89-.95-1.89-2.12s.84-2.12 1.89-2.12c1.06 0 1.9.96 1.89 2.12c0 1.17-.83 2.12-1.89 2.12\"/></svg>"

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

  function isSvg(text) {
    return text && text.indexOf("<svg") === 0
  }

  function svgUri(svg, color) {
    if (!svg) return ""
    let coloredSvg = svg
    if (color) {
      const hex = (typeof color === 'string') ? color : colorHex(color)
      coloredSvg = svg.replace(/currentColor/g, hex)
    }
    return "data:image/svg+xml;utf8," + encodeURIComponent(coloredSvg)
  }

  function colorHex(c) {
    const r = Math.round(c.r * 255).toString(16).padStart(2, "0")
    const g = Math.round(c.g * 255).toString(16).padStart(2, "0")
    const b = Math.round(c.b * 255).toString(16).padStart(2, "0")
    return "#" + r + g + b
  }

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

