import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
  id: root

  required property var item
  property int iconSize: 16

  implicitWidth: iconSize
  implicitHeight: iconSize

  IconImage {
    anchors.fill: parent
    implicitSize: root.iconSize
    source: {
      const icon = item.icon || ""
      return (icon.startsWith("/") ? "file://" : "") + icon
    }
    asynchronous: true
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
