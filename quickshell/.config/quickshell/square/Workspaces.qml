import QtQuick
import Quickshell.Hyprland

// Fixed-width square workspace cells, numbered 1-10.
// Empty = dim text on bg. Occupied = text colour + thin accent stripe (top).
// Focused = solid accent fill, bg-coloured text.
Row {
  id: root

  required property var screenName

  spacing: 0

  Connections {
    target: Hyprland
    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  function workspaceFor(idx) {
    const list = Hyprland.workspaces.values
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === idx) return list[i]
    }
    return null
  }

  function isOnThisMonitor(ws) {
    if (!ws || !ws.monitor) return false
    return ws.monitor.name === root.screenName
  }

  Repeater {
    model: 10

    Rectangle {
      id: cell
      required property int index
      readonly property int wsId: index + 1
      readonly property var ws: root.workspaceFor(wsId)
      readonly property bool occupied: ws !== null && ws.toplevels.values.length > 0
      readonly property bool focused: ws !== null && ws.focused && root.isOnThisMonitor(ws)

      width: Theme.wsCellSize
      height: Theme.barHeight
      radius: 0
      color: focused ? Theme.accent : Theme.bg

      Behavior on color {
        ColorAnimation { duration: Theme.animFast }
      }

      // Hairline divider between cells
      Rectangle {
        anchors {
          top: parent.top
          bottom: parent.bottom
          right: parent.right
        }
        width: Theme.hairline
        color: Theme.border
      }

      // Occupied (not focused) — thin accent stripe along the bottom
      Rectangle {
        visible: cell.occupied && !cell.focused
        anchors {
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        height: Theme.stripe
        color: Theme.accent
      }

      Text {
        anchors.centerIn: parent
        text: String(cell.wsId)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMd
        font.bold: cell.focused || cell.occupied
        color: cell.focused ? Theme.bg : (cell.occupied ? Theme.text : Theme.textDim)
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + cell.wsId)
      }
    }
  }
}
