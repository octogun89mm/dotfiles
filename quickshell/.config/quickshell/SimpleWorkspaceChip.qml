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
  implicitWidth: 16
  implicitHeight: Theme.chipHeight

  Rectangle {
    anchors.fill: parent
    visible: root.isFocused
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35) }
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.displayName
    color: root.isFocused
      ? Theme.text
      : root.isVisible
        ? Theme.textMuted
        : root.isOccupied ? Theme.text : Theme.textDim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontTitle
    font.bold: root.isFocused
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    visible: root.isFocused || root.isVisible
    width: parent.width - 4
    height: root.isFocused ? Theme.stripe : Theme.hairline
    color: root.isFocused ? Theme.accent : Theme.border
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
