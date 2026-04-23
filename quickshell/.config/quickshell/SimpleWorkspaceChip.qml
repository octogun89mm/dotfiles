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

  color: "transparent"
  implicitWidth: Math.max(label.implicitWidth, focusedIndicator.implicitWidth) + 10
  implicitHeight: 20

  Item {
    id: focusedIndicator
    anchors.centerIn: parent
    visible: root.isFocused
    implicitWidth: 14
    implicitHeight: 14

    Rectangle {
      id: focusedDiamond
      anchors.centerIn: parent
      width: 10
      height: 10
      color: Wallust.accent
      rotation: 45
    }

    Rectangle {
      id: focusedSpinner
      anchors.centerIn: parent
      width: 6
      height: 6
      color: Wallust.background
      radius: 0
      transformOrigin: Item.Center

      SequentialAnimation on rotation {
        running: root.isFocused
        loops: Animation.Infinite

        NumberAnimation { to: 45; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 90; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 135; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 180; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 225; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 270; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 315; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
        NumberAnimation { to: 360; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 2200 }
      }
    }
  }

  Text {
    id: label
    anchors.centerIn: parent
    visible: !root.isFocused
    text: root.isOccupied ? "◆" : "■"
    color: {
      if (root.isVisible) return Wallust.accent
      if (root.isOccupied) return Wallust.base05
      return Wallust.base03
    }
    font.family: "Iosevka"
    font.pixelSize: 12
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    transformOrigin: Item.Center
    scale: root.isOccupied ? 1.5 : 1.0
    opacity: 1.0
    Behavior on scale {
      NumberAnimation { duration: 320; easing.type: Easing.OutBack }
    }

    Behavior on color {
      ColorAnimation { duration: 320; easing.type: Easing.InOutSine }
    }
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
