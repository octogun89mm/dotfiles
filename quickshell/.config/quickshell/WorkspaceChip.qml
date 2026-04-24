import QtQuick
import Quickshell.Hyprland
import "wallust.js" as Wallust

Rectangle {
  required property var workspace
  required property string displayName

  property int windowCount: workspace.toplevels.values.length
  property bool isSpecialWorkspace: workspace.name.startsWith("special:")
  property var monitorState: workspace.monitor ? workspace.monitor.lastIpcObject : null
  
  property bool isHighlighted: workspace.focused
  || (
    isSpecialWorkspace
    && monitorState
    && monitorState.specialWorkspace
    && monitorState.specialWorkspace.id === workspace.id
  )

  property color focusedColor: Wallust.base0A
  property color markerColor: isHighlighted ? Wallust.base00 : Wallust.base03

  Connections {
    target: Hyprland

    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  color: isHighlighted ? focusedColor : "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitHeight: 24
  implicitWidth: label.implicitWidth + 24
  
  Text {
    id: label
    anchors.centerIn: parent
    text: displayName
    color: isHighlighted ? Wallust.base00 : Wallust.base05
    font.family: "Iosevka"
    font.pixelSize: 12
    font.bold: true
  }

  Repeater {
    model: Math.min(windowCount, 6)

    Rectangle {
      required property int index

      width: 4
      height: 4
      color: markerColor

      x: {
        switch (index) {
          case 0: return 2
          case 1: return parent.width - width - 2
          case 2: return 2
          case 3: return parent.width - width - 2
          case 4: return Math.round((parent.width - width) / 2)
          case 5: return Math.round((parent.width - width) / 2)
          default: return 2
        }
      }

      y: {
        switch (index) {
          case 0: return 2
          case 1: return 2
          case 2: return parent.height - height - 2
          case 3: return parent.height - height - 2
          case 4: return 2
          case 5: return parent.height - height - 2
          default: return 2
        }
      }
    }
  }
}
