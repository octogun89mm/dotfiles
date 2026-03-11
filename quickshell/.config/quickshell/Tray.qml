import QtQuick
import Quickshell.Services.SystemTray
import "wallust.js" as Wallust

Row {
  spacing: 6
  property bool expanded: false
  clip: true

  Repeater {
    model: SystemTray.items

    TrayItem {
      required property var modelData
      item: modelData
      property bool shouldShow: expanded && item.status !== Status.Passive
      width: shouldShow ? 16 : 0
      opacity: shouldShow ? 1 : 0
      visible: width > 0 || traySlide.running

      Behavior on width {
        NumberAnimation {
          id: traySlide
          duration: 150
          easing.type: Easing.OutQuad
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutQuad
        }
      }
    }
  }

  Item {
    implicitWidth: toggleLabel.implicitWidth
    implicitHeight: toggleLabel.implicitHeight

    Text {
      id: toggleLabel
      anchors.centerIn: parent
      text: expanded ? "󰅂" : "󰅁"
      color: Wallust.base04
      font.family: "Symbols Nerd Font Mono"
      font.pixelSize: 14
    }

    MouseArea {
      anchors.fill: parent
      onClicked: expanded = !expanded
    }
  }
}
