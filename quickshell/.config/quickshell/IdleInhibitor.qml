import QtQuick
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  property string icon: "󰈉"
  property bool inhibited: false
  property string tooltip: "Idle inhibitor: OFF"

  color: "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  function refreshStatus() {
    statusProcess.exec(["/home/juju/.config/waybar/scripts/idle-inhibit.sh"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return

    const data = JSON.parse(text)
    icon = data.alt || "󰈉"
    tooltip = data.tooltip || "Idle inhibitor"
    inhibited = data.class === "activated"
  }

  Component.onCompleted: refreshStatus()

  Text {
    id: indicator
    anchors.centerIn: parent
    text: icon
    color: inhibited ? Wallust.base0D : Wallust.base03
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent

    onClicked: toggleProcess.exec(["/home/juju/.config/waybar/scripts/idle-inhibit.sh", "toggle"])
  }

  FileView {
    path: "/tmp/idle-inhibit.pid"
    preload: true
    watchChanges: true
    printErrors: false

    onFileChanged: refreshStatus()
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      id: statusOutput
      waitForEnd: true
      onStreamFinished: parseStatus(text)
    }
  }

  Process {
    id: toggleProcess
    onExited: refreshStatus()
  }
}
