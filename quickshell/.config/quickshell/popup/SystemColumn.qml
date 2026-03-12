import QtQuick
import Quickshell
import Quickshell.Io

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
  readonly property real cardHeight: Math.max(62, (height - (spacing * 3)) / 4)

  spacing: 10

  MetricCard {
    id: cpuCard
    title: "CPU"
    value: root.cpuUsage.padStart(2, "0") + "%"
    detail: root.cpuTemp.padStart(2, "0") + "°C"
    height: root.cardHeight
  }

  MetricCard {
    id: gpuCard
    title: "GPU"
    value: root.gpuUsage.padStart(2, "0") + "%"
    detail: root.gpuVramUsed + " / " + root.gpuVramTotal + "G"
    detail2: root.gpuTemp.padStart(2, "0") + "°C"
    height: root.cardHeight
  }

  MetricCard {
    id: memoryCard
    title: "MEMORY"
    value: root.memoryUsed.padStart(4, "0") + " / " + root.memoryTotal + "G"
    height: root.cardHeight
  }

  MetricCard {
    id: updatesCard
    title: "UPDATES"
    value: root.updates.padStart(3, "0")
    height: root.cardHeight
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
        } catch (e) {
          console.warn("SystemColumn: failed to parse JSON:", e)
        }
      }
    }
  }
}
