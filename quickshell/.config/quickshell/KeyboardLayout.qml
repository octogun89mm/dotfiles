import QtQuick
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  property string layout: "EN"

  color: "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: root.layout
    color: Wallust.base0D
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }

  Process {
    command: ["/home/juju/.dotfiles/eww/.config/eww/shell/bar_language.sh"]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data || !data.trim()) return
        root.layout = data.trim()
      }
    }
  }
}
