import QtQuick
import Quickshell.Io

ActionCard {
  id: root

  property bool active: false
  property bool inhibited: false

  title: "IDLE"
  icon: inhibited ? "󰈈" : "󰈉"
  value: inhibited ? "INHIBITED" : "NORMAL"
  highlighted: inhibited

  function refreshStatus() {
    statusProcess.exec(["/home/juju/.config/waybar/scripts/idle-inhibit.sh"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return
    const data = JSON.parse(text)
    inhibited = data.class === "activated"
  }

  onClicked: toggleProcess.exec(["/home/juju/.config/waybar/scripts/idle-inhibit.sh", "toggle"])
  onActiveChanged: if (active) refreshStatus()

  FileView {
    path: "/tmp/idle-inhibit.pid"
    preload: true
    watchChanges: true
    printErrors: false
    onFileChanged: root.refreshStatus()
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
