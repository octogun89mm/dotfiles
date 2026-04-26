pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.dotfiles/quickshell/.config/quickshell/scripts/waveform.sh"

  property bool enabled: true
  property bool available: false
  property var samples: []           // each entry: {avg, peak}
  readonly property int maxSamples: 240

  function push(avg, peak) {
    const next = samples.slice()
    next.push({ avg: avg, peak: peak })
    if (next.length > maxSamples) next.splice(0, next.length - maxSamples)
    samples = next
    available = true
  }

  Component.onCompleted: samples = []

  Process {
    id: proc
    command: [root.scriptPath]
    running: root.enabled

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        const line = (data || "").trim()
        if (!line) return
        const parts = line.split(";")
        if (parts.length < 2) return
        const avg = Number(parts[0]) || 0
        const peak = Number(parts[1]) || 0
        root.push(avg, peak)
      }
    }

    onExited: function() {
      root.available = false
      if (root.enabled) restartTimer.restart()
    }
  }

  Timer {
    id: restartTimer
    interval: 1500
    onTriggered: if (root.enabled && !proc.running) proc.running = true
  }
}
