import QtQuick
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  property string icon: "󰒙"
  property bool connected: false
  property string tooltip: "ExpressVPN is disconnected"

  color: "transparent"
  border.width: 2
  border.color: Wallust.base01
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  function refreshStatus() {
    statusProcess.exec(["/home/juju/.config/waybar/scripts/expressvpn.sh"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return

    const data = JSON.parse(text)
    icon = data.alt || "󰒙"
    tooltip = data.tooltip || "ExpressVPN"
    connected = data.class === "vpn-connected"
  }

  Component.onCompleted: refreshStatus()

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: refreshStatus()
  }

  Text {
    id: indicator
    anchors.centerIn: parent
    text: icon
    color: connected ? Wallust.base0D : Wallust.base03
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent
    onClicked: toggleProcess.exec(["/home/juju/.config/waybar/scripts/expressvpn.sh", "toggle"])
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    id: toggleProcess
    onExited: refreshStatus()
  }
}
