import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
  id: root

  required property var item
  property color iconColor: "#BBBBBB"

  implicitWidth: 16
  implicitHeight: 16

  IconImage {
    anchors.fill: parent
    implicitSize: 16
    source: item.icon
    asynchronous: true
    visible: item.id !== "expressvpn"
  }

  Text {
    anchors.centerIn: parent
    text: VpnState.icon
    color: root.iconColor
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
    visible: item.id === "expressvpn"
  }

  QsMenuAnchor {
    id: menuAnchor
    menu: item.menu
    anchor.item: root
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        if (item.onlyMenu && item.hasMenu) {
          menuAnchor.open()
        } else {
          item.activate()
        }
        return
      }

      if (mouse.button === Qt.MiddleButton) {
        item.secondaryActivate()
        return
      }

      if (mouse.button === Qt.RightButton && item.hasMenu) {
        menuAnchor.open()
      }
    }
  }
}
