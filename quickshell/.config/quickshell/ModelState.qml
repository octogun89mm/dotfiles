pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/model-status.sh"

  property bool loaded: false
  property string icon: "󰧑"
  property string tooltip: "No local model loaded"
  property bool ready: false

  function refresh() {
    statusProcess.exec([scriptPath])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return

    try {
      const data = JSON.parse(text)
      loaded = data.loaded === true
      icon = data.icon || "󰧑"
      tooltip = data.tooltip || (loaded ? "Local model loaded" : "No local model loaded")
      ready = true
    } catch (e) {
      console.warn("ModelState: failed to parse status:", e)
    }
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }
}
