pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Download/upload rates from /proc/net/dev deltas, summed over physical
// interfaces (en*/eth*/wl*); lo and virtual/overlay ifaces are ignored.
Singleton {
  id: root

  property real downBps: -1
  property real upBps: -1

  property real _lastRx: -1
  property real _lastTx: -1
  property double _lastStamp: 0

  function format(bps) {
    if (bps < 0) return "--"
    if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M"
    if (bps >= 1024) return Math.round(bps / 1024) + "K"
    return Math.round(bps) + "B"
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!netProc.running) netProc.running = true
    }
  }

  Process {
    id: netProc
    command: ["cat", "/proc/net/dev"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        let rx = 0
        let tx = 0
        for (const line of text.split("\n")) {
          const m = line.match(/^\s*(en|eth|wl)\w*:\s*(\d+)(?:\s+\d+){7}\s+(\d+)/)
          if (!m) continue
          rx += parseInt(m[2])
          tx += parseInt(m[3])
        }
        const now = Date.now()
        if (root._lastStamp > 0 && now > root._lastStamp) {
          const dt = (now - root._lastStamp) / 1000
          root.downBps = Math.max(0, (rx - root._lastRx) / dt)
          root.upBps = Math.max(0, (tx - root._lastTx) / dt)
        }
        root._lastRx = rx
        root._lastTx = tx
        root._lastStamp = now
      }
    }
  }
}
