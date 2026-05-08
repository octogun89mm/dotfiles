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

  function isWifiItem() {
    const key = itemKey()
    return key.includes("nm-applet")
      || key.includes("network-manager")
      || key.includes("network_manager")
      || key.includes("network")
      || key.includes("wireless")
      || key.includes("wifi")
      || key.includes("wi-fi")
      || key.includes("wlan")
      || key.includes("nm-signal")
  }

  function colorHex(colorValue) {
    const r = Math.round(colorValue.r * 255).toString(16).padStart(2, "0")
    const g = Math.round(colorValue.g * 255).toString(16).padStart(2, "0")
    const b = Math.round(colorValue.b * 255).toString(16).padStart(2, "0")
    return "#" + r + g + b
  }

  function svgUri(svg) {
    return "data:image/svg+xml;utf8," + encodeURIComponent(svg)
  }

  function wifiSvg() {
    const stroke = colorHex(root.iconColor)
    return svgUri("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>"
      + "<g fill='none' stroke='" + stroke + "' stroke-width='1.6' stroke-linecap='round'>"
      + "<path d='M2.2 6.2c3.2-2.7 8.4-2.7 11.6 0'/>"
      + "<path d='M4.7 8.7c1.8-1.5 4.8-1.5 6.6 0'/>"
      + "<path d='M7.2 11.2c.5-.4 1.1-.4 1.6 0'/>"
      + "</g>"
      + "<circle cx='8' cy='13.1' r='1.1' fill='" + stroke + "'/>"
      + "</svg>")
  }

  function symbolicIcon() {
    const key = itemKey()
    if (key.includes("signal")) return "󰭹"
    if (key.includes("firefox") || key.includes("zen")) return ""
    if (key.includes("chrom") || key.includes("brave") || key.includes("helium")) return ""
    if (key.includes("kitty") || key.includes("wezterm") || key.includes("alacritty") || key.includes("terminal")) return ""
    if (key.includes("code") || key.includes("cursor") || key.includes("codium")) return ""
    if (key.includes("discord")) return ""
    if (key.includes("spotify")) return ""
    if (key.includes("steam")) return ""
    if (key.includes("file") || key.includes("nautilus") || key.includes("thunar") || key.includes("dolphin")) return ""
    if (key.includes("obsidian") || key.includes("notes")) return "󰎞"
    if (key.includes("gimp") || key.includes("krita") || key.includes("inkscape")) return ""
    if (key.includes("mpv") || key.includes("vlc")) return ""
    if (key.includes("expressvpn") || key.includes("vpn")) return VpnState.icon
    if (key.includes("bluetooth")) return "󰂯"
    if (key.includes("nm-applet")
        || key.includes("network-manager")
        || key.includes("network_manager")
        || key.includes("network")
        || key.includes("wireless")
        || key.includes("wifi")
        || key.includes("wi-fi")
        || key.includes("wlan")
        || key.includes("nm-signal")) return ""
    if (key.includes("volume") || key.includes("audio")) return "󰕾"
    if (key.includes("battery") || key.includes("power")) return "󰁹"
    if (key.includes("syncthing")) return "󰓦"
    return ""
  }

  IconImage {
    anchors.fill: parent
    implicitSize: root.iconSize
    source: item.icon
    asynchronous: true
    visible: !root.symbolic && item.id !== "expressvpn"
  }

  Image {
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize
    sourceSize.width: root.iconSize
    sourceSize.height: root.iconSize
    source: root.symbolic && root.isWifiItem() ? root.wifiSvg() : ""
    asynchronous: true
    visible: root.symbolic && root.isWifiItem()
  }

  Text {
    anchors.centerIn: parent
    text: root.symbolic ? root.symbolicIcon() : VpnState.icon
    color: root.iconColor
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: Math.max(9, root.iconSize - 1)
    visible: (root.symbolic && !root.isWifiItem()) || item.id === "expressvpn"
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
