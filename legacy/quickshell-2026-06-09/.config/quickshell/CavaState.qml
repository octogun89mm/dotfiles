pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string configPath: home + "/.dotfiles/quickshell/.config/quickshell/ressources/cava-bar.conf"
  readonly property int barCount: 4
  readonly property int rawBarCount: barCount * 2

  property bool enabled: true
  property bool available: false
  property var leftBars: []
  property var rightBars: []

  // Rolling auto-gain: track recent peak with slow decay, normalise bars to it.
  property bool autoGain: true
  property real peak: 0.15
  readonly property real peakFloor: 0.08    // never amplify above ~12x
  readonly property real peakDecay: 0.985   // per-frame decay toward floor
  readonly property real attackBlend: 0.4   // how fast peak rises on louder frame

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
    let frameMax = 0
    for (let i = 0; i < barCount; i++) {
      const leftValue = Math.max(0, Math.min(1, Number(parts[i] || 0) / 100))
      const rightValue = Math.max(0, Math.min(1, Number(parts[barCount + i] || 0) / 100))
      left.push(leftValue)
      right.push(rightValue)
      if (leftValue > frameMax) frameMax = leftValue
      if (rightValue > frameMax) frameMax = rightValue
    }

    if (autoGain) {
      // Decay peak toward the floor; let louder frames pull peak up quickly.
      const decayed = Math.max(peakFloor, peak * peakDecay)
      peak = frameMax > decayed ? (decayed * (1 - attackBlend) + frameMax * attackBlend) : decayed

      const gain = 1 / peak
      for (let j = 0; j < barCount; j++) {
        left[j] = Math.max(0, Math.min(1, left[j] * gain))
        right[j] = Math.max(0, Math.min(1, right[j] * gain))
      }
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

  property bool isScope: CavaStyleState.current === "scope"
  property bool isOff: CavaStyleState.current === "off"

  Process {
    id: cavaProcess
    command: ["/usr/bin/cava", "-p", root.configPath]
    running: root.enabled && !root.isScope && !root.isOff

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
      if (root.enabled && !root.isScope && !root.isOff && !cavaProcess.running) {
        cavaProcess.running = true
      }
    }
  }
}
