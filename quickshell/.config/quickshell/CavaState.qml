pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string configPath: home + "/.dotfiles/quickshell/.config/quickshell/ressources/cava-bar.conf"
  readonly property int barCount: 6
  readonly property int rawBarCount: barCount * 2

  property bool enabled: true
  property bool available: false
  property var leftBars: []
  property var rightBars: []

  function zeroBars() {
    return Array(barCount).fill(0)
  }

  function parseFrame(data) {
    const line = data ? data.trim() : ""
    if (!line) return

    const parts = line.split(";").filter(part => part.length > 0)
    if (parts.length < rawBarCount) return

    const left = []
    const right = []
    for (let i = 0; i < barCount; i++) {
      const leftValue = Number(parts[i] || 0)
      const rightValue = Number(parts[barCount + i] || 0)

      left.push(Math.max(0, Math.min(1, leftValue / 100)))
      right.push(Math.max(0, Math.min(1, rightValue / 100)))
    }

    leftBars = left
    rightBars = right.reverse()
    available = true
  }

  Component.onCompleted: {
    leftBars = zeroBars()
    rightBars = zeroBars()
  }

  onEnabledChanged: {
    if (!enabled) {
      available = false
      leftBars = zeroBars()
      rightBars = zeroBars()
    }
  }

  Process {
    id: cavaProcess
    command: ["/usr/bin/cava", "-p", root.configPath]
    running: root.enabled

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        root.parseFrame(data)
      }
    }

    onExited: function() {
      if (root.enabled) {
        root.available = false
        restartTimer.restart()
      }
    }
  }

  Timer {
    id: restartTimer
    interval: 1000
    repeat: false
    onTriggered: {
      if (root.enabled && !cavaProcess.running) {
        cavaProcess.running = true
      }
    }
  }
}
