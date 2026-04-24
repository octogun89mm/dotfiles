pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/mic-in-use.sh"

  property bool active: false
  property var apps: []
  property bool ready: false

  function refresh() {
    statusProcess.running = false
    statusProcess.exec([scriptPath])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return
    try {
      const data = JSON.parse(text)
      const nextActive = !!data.active
      const nextApps = Array.isArray(data.apps) ? data.apps : []

      if (ready && nextActive !== active) {
        OsdState.show(nextActive ? "󰍬" : "󰍭",
          nextActive
            ? "MIC IN USE" + (nextApps.length ? " · " + nextApps.join(", ") : "")
            : "MIC FREE")
      }

      root.active = nextActive
      root.apps = nextApps
      root.ready = true
    } catch (e) {
      console.warn("MicState: failed to parse:", e)
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    command: ["pactl", "subscribe"]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data) return
        if (data.indexOf("source-output") !== -1 || data.indexOf("on source #") !== -1 || data.indexOf("on client") !== -1) {
          debounce.restart()
        }
      }
    }
  }

  Timer {
    id: debounce
    interval: 120
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
}
