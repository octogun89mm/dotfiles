import QtQuick
import Quickshell.Io

Item {
  id: root

  property int sessionCount: 0
  property int attachedCount: 0

  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth

  function refresh() {
    if (!tmuxProcess.running) {
      tmuxProcess.exec(["tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}"])
    }
  }

  function parseSessions(text) {
    const lines = String(text || "").trim().split("\n").filter(line => line.length > 0)
    let attached = 0

    for (let i = 0; i < lines.length; i++) {
      const parts = lines[i].split(":")
      if (parts.length > 1 && Number(parts[parts.length - 1]) > 0) attached += 1
    }

    sessionCount = lines.length
    attachedCount = attached
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      color: Theme.textMuted
      font.family: Theme.iconFamily
      font.pixelSize: Theme.fontLg
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(root.sessionCount)
      color: root.sessionCount > 0 ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
      font.bold: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.attachedCount > 0
      text: "(" + root.attachedCount + ")"
      color: Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSm
    }
  }

  Process {
    id: tmuxProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseSessions(text)
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.sessionCount = 0
        root.attachedCount = 0
      }
    }
  }
}
