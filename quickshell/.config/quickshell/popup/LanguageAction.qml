import QtQuick
import Quickshell.Io

ActionCard {
  id: root

  property bool active: false
  property string layout: "EN"

  title: "LAYOUT"
  icon: "󰌌"
  value: layout
  highlighted: false

  Process {
    running: root.active
    command: ["/home/juju/.dotfiles/eww/.config/eww/shell/bar_language.sh"]

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data || !data.trim()) return
        root.layout = data.trim()
      }
    }
  }
}
