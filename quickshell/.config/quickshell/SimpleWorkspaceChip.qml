import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
  id: root

  required property int workspaceId
  required property string displayName
  property int leadingGap: 0
  property var windowIcons: []

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
  readonly property bool isOccupied: windowIcons.length > 0 || (workspaceData ? workspaceData.toplevels.values.length > 0 : false)
  readonly property bool isHighlighted: isFocused || isVisible
  readonly property int baseChipWidth: Math.max(20, chipContent.implicitWidth + Theme.padSm * 2)
  readonly property int chipWidth: baseChipWidth + (isFocused ? Theme.padLg : isVisible ? Theme.padMd : 0)

  color: "transparent"
  implicitWidth: leadingGap + chipWidth
  implicitHeight: Theme.chipHeight

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  Rectangle {
    x: root.leadingGap
    width: root.chipWidth
    height: parent.height
    visible: root.isFocused
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35) }
    }

    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }

  Row {
    id: chipContent
    anchors.verticalCenter: parent.verticalCenter
    x: root.leadingGap + Math.round((root.chipWidth - implicitWidth) / 2)
    spacing: 2

    Behavior on x {
      NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.displayName
      color: root.isFocused
        ? Theme.foreground
        : root.isVisible
          ? Theme.foreground
          : root.isOccupied ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: 16
      font.bold: root.isFocused
    }

    Repeater {
      model: root.windowIcons

      Item {
        required property var modelData
        readonly property bool isSvg: WindowIcons.isSvgRef(modelData.icon)
        readonly property color iconColor: root.isFocused || root.isVisible ? Theme.foreground : Theme.textDim
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: (isSvg ? iconImage.width : iconLabel.implicitWidth) + (countLabel.visible ? countLabel.implicitWidth + 1 : 0)
        implicitHeight: Math.max(isSvg ? iconImage.height : iconLabel.implicitHeight, countLabel.visible ? countLabel.implicitHeight + 2 : 0)

        Text {
          id: iconLabel
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: !parent.isSvg
          text: parent.isSvg ? "" : modelData.icon
          color: parent.iconColor
          font.family: Theme.iconFamily
          font.pixelSize: 9
        }

        Image {
          id: iconImage
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: parent.isSvg
          width: 10
          height: 10
          sourceSize.width: 10
          sourceSize.height: 10
          source: parent.isSvg ? WindowIcons.svgUri(modelData.icon, parent.iconColor) : ""
          asynchronous: true
        }

        Text {
          id: countLabel
          anchors.left: parent.isSvg ? iconImage.right : iconLabel.right
          anchors.leftMargin: 1
          anchors.top: parent.top
          anchors.topMargin: -2
          visible: modelData.count > 1
          text: modelData.count
          color: root.isFocused || root.isVisible ? Theme.foreground : Theme.textDim
          font.family: Theme.fontFamily
          font.pixelSize: 8
          font.bold: true
        }
      }
    }
  }

  Rectangle {
    anchors.bottom: parent.bottom
    x: root.leadingGap + 2
    visible: root.isFocused || root.isVisible
    width: root.chipWidth - 4
    height: root.isFocused ? Theme.stripe : Theme.hairline
    color: root.isFocused ? Theme.accent : Theme.border

    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: workspaceProcess.exec(["hyprctl", "dispatch", "workspace", String(root.workspaceId)])
  }

  Process {
    id: workspaceProcess
  }
}
