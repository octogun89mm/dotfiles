pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polls CPU/RAM usage via the shared system-metrics.sh helper script.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/system-metrics.sh"

  property real cpuUsage: -1
  property real cpuTemp: -1
  property real memPercent: -1
  property real gpuUsage: -1
  property real gpuTemp: -1
  property real vramPercent: -1

  function refresh() {
    if (metricsProc.running) return
    metricsProc.exec([scriptPath])
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: metricsProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        try {
          const d = JSON.parse(text)
          const num = function(v) {
            const n = parseFloat(v)
            return isNaN(n) ? -1 : n
          }
          root.cpuUsage = num(d.cpu)
          root.cpuTemp = num(d.cpu_temp)
          root.gpuUsage = num(d.gpu)
          root.gpuTemp = num(d.gpu_temp)
          const memUsed = num(d.mem_used)
          const memTotal = num(d.mem_total)
          root.memPercent = (memTotal > 0 && memUsed >= 0)
            ? (memUsed / memTotal * 100)
            : -1
          const vramUsed = num(d.gpu_vram_used)
          const vramTotal = num(d.gpu_vram_total)
          root.vramPercent = (vramTotal > 0 && vramUsed >= 0)
            ? (vramUsed / vramTotal * 100)
            : -1
        } catch (e) {
          console.warn("MetricsState: failed to parse:", e)
        }
      }
    }
  }
}
