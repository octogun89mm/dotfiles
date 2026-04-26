pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.dotfiles/quickshell/.config/quickshell/scripts/system-metrics.sh"

  property real cpuUsage: -1
  property real cpuTemp: -1
  property real load1: -1
  property real gpuUsage: -1
  property real gpuTemp: -1
  property real gpuVramUsed: -1
  property real gpuVramTotal: -1
  property real memUsed: -1
  property real memTotal: -1
  property real memPercent: -1
  property int updates: -1

  property var cpuHistory: []
  property var memHistory: []
  property var gpuHistory: []
  readonly property int maxHistory: 30

  function pushHist(arr, val) {
    const next = arr.slice()
    next.push(val)
    while (next.length > maxHistory) next.shift()
    return next
  }

  function refresh() {
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
          root.load1 = num(d.load1)
          root.gpuUsage = num(d.gpu)
          root.gpuTemp = num(d.gpu_temp)
          root.gpuVramUsed = num(d.gpu_vram_used)
          root.gpuVramTotal = num(d.gpu_vram_total)
          root.memUsed = num(d.mem_used)
          root.memTotal = num(d.mem_total)
          root.memPercent = (root.memTotal > 0 && root.memUsed >= 0)
            ? (root.memUsed / root.memTotal * 100)
            : -1
          root.updates = num(d.updates) | 0

          if (root.cpuUsage >= 0) root.cpuHistory = root.pushHist(root.cpuHistory, root.cpuUsage)
          if (root.memPercent >= 0) root.memHistory = root.pushHist(root.memHistory, root.memPercent)
          if (root.gpuUsage >= 0) root.gpuHistory = root.pushHist(root.gpuHistory, root.gpuUsage)
        } catch (e) {
          console.warn("MetricsState: failed to parse:", e)
        }
      }
    }
  }
}
