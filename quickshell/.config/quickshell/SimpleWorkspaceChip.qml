import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

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

  color: "transparent"
  implicitWidth: 14
  implicitHeight: Theme.chipHeight

  // Focused: solid 10x10 cyan square
  Rectangle {
    anchors.centerIn: parent
    visible: root.isFocused
    width: 10
    height: 10
    color: Theme.accent
  }

  // Visible on another monitor: 10x10 hollow cyan square (2px stroke)
  Rectangle {
    anchors.centerIn: parent
    visible: root.isVisible && !root.isFocused
    width: 10
    height: 10
    color: "transparent"
    border.width: Theme.stripe
    border.color: Theme.accent
  }

  // Occupied but not visible: dim diamond
  Text {
    anchors.centerIn: parent
    visible: !root.isVisible && root.isOccupied
    text: "◆"
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
  }

  // Empty: tiny dot
  Rectangle {
    anchors.centerIn: parent
    visible: !root.isVisible && !root.isOccupied
    width: 3
    height: 3
    color: Theme.textDim
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
