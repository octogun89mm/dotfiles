import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  required property int workspaceId
  required property string displayName

  readonly property var workspaceData: {
    const workspaces = Hyprland.workspaces.values

    for (let i = 0; i < workspaces.length; i++) {
      if (workspaces[i].id === workspaceId)
        return workspaces[i]
    }

    return null
  }

  readonly property bool isFocused: workspaceData ? workspaceData.focused : false
  readonly property bool isVisible: {
    const monitors = Hyprland.monitors.values

    for (let i = 0; i < monitors.length; i++) {
      const activeWorkspace = monitors[i].activeWorkspace
      if (activeWorkspace && activeWorkspace.id === workspaceId)
        return true
    }

    return false
  }
  readonly property bool isOccupied: workspaceData ? workspaceData.toplevels.values.length > 0 : false

  color: isFocused ? Wallust.accent : "transparent"
  implicitWidth: label.implicitWidth + 14
  implicitHeight: 20

  Text {
    id: label
    anchors.centerIn: parent
    text: root.displayName
    color: {
      if (root.isFocused) return Wallust.base00
      if (root.isVisible) return Wallust.accent
      if (root.isOccupied) return Wallust.base05
      return Wallust.base03
    }
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }

  MouseArea {
    anchors.fill: parent
    onClicked: workspaceProcess.exec(["hyprctl", "dispatch", "workspace", String(root.workspaceId)])
  }

  Connections {
    target: Hyprland

    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  Process {
    id: workspaceProcess
  }
}
