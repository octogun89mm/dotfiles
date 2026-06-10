import QtQuick
import Quickshell.Hyprland

// All workspaces, on every bar — each cell wears the colour of the
// monitor it lives on. Exactly one solid cell per screen (its active
// workspace), so any single bar is a complete map of every monitor.
//   solid fill          = active workspace of that monitor
//   bold + solid fill   = where the keyboard focus is
//   coloured understripe = occupied, inactive
//   critical fill       = urgent
Row {
  id: root

  spacing: 0

  Connections {
    target: Hyprland
    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  readonly property var allWorkspaces: {
    return Hyprland.workspaces.values
      .filter(ws => !ws.name.startsWith("special:"))
      .sort((a, b) => a.id - b.id)
  }

  Repeater {
    model: root.allWorkspaces

    Rectangle {
      id: cell
      required property var modelData
      readonly property var ws: modelData
      readonly property bool active: ws.active
      readonly property bool focused: ws.focused
      readonly property bool urgent: ws.urgent === true
      readonly property bool occupied: ws.toplevels.values.length > 0
      readonly property color monitorColor: ws.monitor
        ? Theme.monitorAccent(ws.monitor.id)
        : Theme.surface

      implicitWidth: label.implicitWidth + Theme.padLg * 2
      implicitHeight: Theme.barHeight
      radius: 0
      color: cell.urgent ? Theme.critical
        : cell.active ? cell.monitorColor
        : Theme.bg

      Behavior on color {
        ColorAnimation { duration: Theme.animFast }
      }

      Rectangle {
        visible: !cell.active && !cell.urgent && cell.occupied
        anchors {
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        height: Theme.stripe
        color: cell.monitorColor
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: cell.ws.name
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMd
        font.bold: true
        color: (cell.active || cell.urgent) ? Theme.bg
          : cell.occupied ? Theme.text
          : Theme.textDim
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + cell.ws.id)
      }
    }
  }
}
