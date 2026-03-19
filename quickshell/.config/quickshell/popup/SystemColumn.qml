import QtQuick
import Quickshell
import Quickshell.Io
import "../wallust.js" as Wallust

Column {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string metricsScript: home + "/.dotfiles/quickshell/.config/quickshell/scripts/system-metrics.sh"

  property bool active: false
  property string cpuUsage: "--"
  property string cpuTemp: "--"
  property string memoryUsed: "--"
  property string memoryTotal: "--"
  property string updates: "--"
  property string gpuUsage: "--"
  property string gpuTemp: "--"
  property string gpuVramUsed: "--"
  property string gpuVramTotal: "--"

  property var cpuUsageHistory: []
  property var cpuTempHistory: []
  property var gpuUsageHistory: []
  property var gpuVramHistory: []
  property var gpuTempHistory: []
  property var memUsageHistory: []
  property var memLoadHistory: []

  readonly property int maxHistory: 30
  readonly property real updatesHeight: 50
  readonly property real graphCardHeight: Math.max(80, (height - updatesHeight - (spacing * 3)) / 3)

  spacing: 10

  MetricCard {
    id: cpuCard
    title: "CPU"
    value: root.cpuUsage.padStart(2, "0") + "%"
    detail: root.cpuTemp.padStart(2, "0") + "°C"
    height: root.graphCardHeight
    graphs: [
      {values: root.cpuUsageHistory, color: Wallust.accent, label: "USE", maxValue: 100},
      {values: root.cpuTempHistory, color: Wallust.base08, label: "TMP", maxValue: 100}
    ]
  }

  MetricCard {
    id: gpuCard
    title: "GPU"
    value: root.gpuUsage.padStart(2, "0") + "%"
    detail: root.gpuVramUsed + " / " + root.gpuVramTotal + "G"
    detail2: root.gpuTemp.padStart(2, "0") + "°C"
    height: root.graphCardHeight
    graphs: [
      {values: root.gpuUsageHistory, color: Wallust.base0B, label: "USE", maxValue: 100},
      {values: root.gpuVramHistory, color: Wallust.base0E, label: "VRAM", maxValue: parseFloat(root.gpuVramTotal) || 16},
      {values: root.gpuTempHistory, color: Wallust.base08, label: "TMP", maxValue: 100}
    ]
  }

  MetricCard {
    id: memoryCard
    title: "MEMORY"
    value: root.memoryUsed.padStart(4, "0") + " / " + root.memoryTotal + "G"
    height: root.graphCardHeight
    graphs: [
      {values: root.memUsageHistory, color: Wallust.accent, label: "USE", maxValue: 100},
      {values: root.memLoadHistory, color: Wallust.base0E, label: "LOAD", maxValue: parseFloat(root.memoryTotal) || 32}
    ]
  }

  MetricCard {
    id: updatesCard
    title: "UPDATES"
    value: root.updates.padStart(3, "0")
    height: root.updatesHeight
  }

  function pushHistory(arr, val) {
    return arr.concat([val]).slice(-maxHistory)
  }

  function refreshMetrics() {
    metricsProcess.exec([metricsScript])
  }

  function formatInt(value, fallback) {
    if (value === null || value === undefined || value === "") return fallback
    return String(value)
  }

  onActiveChanged: {
    if (active) refreshMetrics()
  }

  Timer {
    interval: 3000
    running: root.active
    repeat: true
    onTriggered: root.refreshMetrics()
  }

  Process {
    id: metricsProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        try {
          const data = JSON.parse(text)
          root.cpuUsage = root.formatInt(data.cpu, "--")
          root.cpuTemp = root.formatInt(data.cpu_temp, "--")
          root.memoryUsed = data.mem_used || "--"
          root.memoryTotal = data.mem_total || "--"
          root.updates = root.formatInt(data.updates, "--")
          root.gpuUsage = root.formatInt(data.gpu, "--")
          root.gpuTemp = root.formatInt(data.gpu_temp, "--")

          const used = parseFloat(data.gpu_vram_used || 0)
          root.gpuVramUsed = isNaN(used) ? "--" : used.toFixed(1).padStart(4, "0")
          root.gpuVramTotal = data.gpu_vram_total || "--"

          var v
          v = parseFloat(data.cpu)
          if (!isNaN(v)) root.cpuUsageHistory = root.pushHistory(root.cpuUsageHistory, v)
          v = parseFloat(data.cpu_temp)
          if (!isNaN(v)) root.cpuTempHistory = root.pushHistory(root.cpuTempHistory, v)
          v = parseFloat(data.gpu)
          if (!isNaN(v)) root.gpuUsageHistory = root.pushHistory(root.gpuUsageHistory, v)
          v = parseFloat(data.gpu_vram_used)
          if (!isNaN(v)) root.gpuVramHistory = root.pushHistory(root.gpuVramHistory, v)
          v = parseFloat(data.gpu_temp)
          if (!isNaN(v)) root.gpuTempHistory = root.pushHistory(root.gpuTempHistory, v)

          var memUsed = parseFloat(data.mem_used)
          var memTotal = parseFloat(data.mem_total)
          if (!isNaN(memUsed) && !isNaN(memTotal) && memTotal > 0) {
            root.memUsageHistory = root.pushHistory(root.memUsageHistory, memUsed / memTotal * 100)
            root.memLoadHistory = root.pushHistory(root.memLoadHistory, memUsed)
          }
        } catch (e) {
          console.warn("SystemColumn: failed to parse JSON:", e)
        }
      }
    }
  }

  Process {
    id: controlProcess
  }
}
