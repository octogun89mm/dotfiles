pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.dotfiles/eww/.config/eww/shell/bar_language.sh"

  property string layout: "EN"
  property bool ready: false

  Process {
    command: [root.scriptPath]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data || !data.trim()) return

        const nextLayout = data.trim()
        const changed = root.ready && nextLayout !== root.layout

        root.layout = nextLayout

        if (changed) {
          OsdState.show("󰌌", "KB " + root.layout)
        }

        root.ready = true
      }
    }
  }
}
