pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tracks whether the mic is currently captured by any app, via mic-in-use.sh.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/mic-in-use.sh"

  property bool active: false

  function refresh() {
    if (statusProcess.running) return
    statusProcess.exec([scriptPath])
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        try {
          const data = JSON.parse(text)
          root.active = !!data.active
        } catch (e) {
          console.warn("MicState: failed to parse:", e)
        }
      }
    }
  }

  Process {
    command: ["pactl", "subscribe"]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data) return
        if (data.indexOf("source-output") !== -1 || data.indexOf("on source #") !== -1) {
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
