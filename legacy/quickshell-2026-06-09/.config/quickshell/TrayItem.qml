import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
  id: root

  required property var item
  property color iconColor: "#BBBBBB"
  property int iconSize: 16
  property bool symbolic: false

  implicitWidth: iconSize
  implicitHeight: iconSize

  function itemKey() {
    if (!item) return ""
    return [
      item.id,
      item.title,
      item.icon,
      item.tooltipTitle,
      item.tooltipDescription
    ].filter(function(part) {
      return part !== undefined && part !== null && String(part).length > 0
    }).join(" ").toLowerCase()
  }

  function symbolicIcon() {
    const key = itemKey()
    if (key.includes("expressvpn") || key.includes("vpn")) return VpnState.icon
    const tray = WindowIcons.iconForTray(key)
    if (tray !== WindowIcons.fallback) return tray
    const app = WindowIcons.iconForApp(key)
    if (app !== WindowIcons.fallback) return app
    return ""
  }

  readonly property string symbolicValue: symbolicIcon()
  readonly property bool symbolicIsSvg: WindowIcons.isSvgRef(symbolicValue)

  IconImage {
    anchors.fill: parent
    implicitSize: root.iconSize
    source: {
      const icon = item.icon || ""
      return (icon.startsWith("/") ? "file://" : "") + icon
    }
    asynchronous: true
    visible: !root.symbolic && item.id !== "expressvpn"
  }

  Image {
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize
    sourceSize.width: root.iconSize
    sourceSize.height: root.iconSize
    source: root.symbolic && root.symbolicIsSvg ? WindowIcons.svgUri(root.symbolicValue, root.iconColor) : ""
    asynchronous: true
    visible: root.symbolic && root.symbolicIsSvg
  }

  Text {
    anchors.centerIn: parent
    text: root.symbolic ? (root.symbolicIsSvg ? "" : root.symbolicValue) : VpnState.icon
    color: root.iconColor
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: Math.max(9, root.iconSize - 1)
    visible: (root.symbolic && !root.symbolicIsSvg) || item.id === "expressvpn"
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
