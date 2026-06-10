pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/network-status.sh"

  property string iface: ""
  property real downMbps: 0
  property real upMbps: 0
  property int signal: 0

  property real lastRx: -1
  property real lastTx: -1
  property real lastStamp: 0
  property real currentStamp: 0

  function refresh() {
    currentStamp += 1000
    if (!networkProc.running) networkProc.exec([scriptPath])
  }

  function formatRate(value) {
    if (value >= 100) return value.toFixed(0)
    if (value >= 10) return value.toFixed(1)
    return value.toFixed(2)
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: networkProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return

        try {
          const data = JSON.parse(text.trim())
          const now = root.currentStamp
          const rx = Number(data.rx || 0)
          const tx = Number(data.tx || 0)

          root.iface = String(data.iface || "")
          root.signal = Math.max(0, Math.min(100, Number(data.signal || 0)))

          if (root.lastRx >= 0 && root.lastTx >= 0 && root.lastStamp > 0) {
            const elapsed = Math.max(0.001, (now - root.lastStamp) / 1000)
            root.downMbps = Math.max(0, (rx - root.lastRx) / 1000000 / elapsed)
            root.upMbps = Math.max(0, (tx - root.lastTx) / 1000000 / elapsed)
          }

          root.lastRx = rx
          root.lastTx = tx
          root.lastStamp = now
        } catch (e) {
          console.warn("NetworkState: failed to parse:", e)
        }
      }
    }
  }
}
