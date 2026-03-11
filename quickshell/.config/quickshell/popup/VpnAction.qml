import QtQuick
import Quickshell.Io

ActionCard {
  id: root

  property bool active: false

  title: "VPN"
  icon: connected ? "󰒘" : "󰒙"
  value: connected ? "CONNECTED" : "DISCONNECTED"
  highlighted: connected

  property bool connected: false

  function refreshStatus() {
    statusProcess.exec(["/home/juju/.config/waybar/scripts/expressvpn.sh"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return
    const data = JSON.parse(text)
    connected = data.class === "vpn-connected"
  }

  onClicked: toggleProcess.exec(["/home/juju/.config/waybar/scripts/expressvpn.sh", "toggle"])
  onActiveChanged: if (active) refreshStatus()

  Timer {
    interval: 10000
    running: root.active
    repeat: true
    onTriggered: root.refreshStatus()
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
    onExited: root.refreshStatus()
  }
}
