import QtQuick
import Quickshell.Hyprland

// Swaybar-style workspace buttons for THIS monitor only.
// Empty/nonexistent workspaces are hidden entirely.
// focused = solid monitor-accent fill, bg-coloured text.
// occupied-but-unfocused = text on a slightly elevated surface.
// urgent = critical fill.
Row {
  id: root

  required property var screenName
  required property color accentColor

  spacing: 0

  Connections {
    target: Hyprland
    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  readonly property var workspacesHere: {
    return Hyprland.workspaces.values
      .filter(ws => ws.monitor && ws.monitor.name === root.screenName
        && !ws.name.startsWith("special:"))
      .sort((a, b) => a.id - b.id)
  }

  Repeater {
    model: root.workspacesHere

    Rectangle {
      id: cell
      required property var modelData
      readonly property var ws: modelData
      readonly property bool focused: ws.focused
      readonly property bool urgent: ws.urgent === true
      readonly property bool occupied: ws.toplevels.values.length > 0

      implicitWidth: label.implicitWidth + Theme.padLg * 2
      implicitHeight: Theme.barHeight
      radius: 0
      color: cell.urgent ? Theme.critical
        : cell.focused ? root.accentColor
        : cell.occupied ? Theme.surface
        : Theme.bg

      Behavior on color {
        ColorAnimation { duration: Theme.animFast }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: cell.ws.name
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMd
        font.bold: cell.focused || cell.urgent
        color: (cell.focused || cell.urgent) ? Theme.bg : Theme.text
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + cell.ws.id)
      }
    }
  }
}
