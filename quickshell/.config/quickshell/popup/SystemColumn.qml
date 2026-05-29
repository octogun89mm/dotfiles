import QtQuick
import "../wallust.js" as Wallust
import "../"

Column {
  id: root

  property bool active: false

  property var cpuUsageHistory: []
  property var cpuTempHistory: []
  property var gpuUsageHistory: []
  property var gpuVramHistory: []
  property var gpuTempHistory: []
  property var memUsageHistory: []
  property var memLoadHistory: []

  readonly property int maxHistory: 30
  readonly property real graphCardHeight: Math.max(80, (height - (spacing * 2)) / 3)

  spacing: 10

  MetricCard {
    id: cpuCard
    title: "CPU"
    value: MetricsState.cpuUsage >= 0
      ? String(Math.round(MetricsState.cpuUsage)).padStart(2, "0") + "%"
      : "--"
    detail: MetricsState.cpuTemp >= 0
      ? String(Math.round(MetricsState.cpuTemp)).padStart(2, "0") + "°C"
      : "--"
    height: root.graphCardHeight
    graphs: [
      {values: root.cpuUsageHistory, color: Wallust.accent, label: "USE", maxValue: 100},
      {values: root.cpuTempHistory, color: Wallust.base08, label: "TMP", maxValue: 100}
    ]
  }

  MetricCard {
    id: gpuCard
    title: "GPU"
    value: MetricsState.gpuUsage >= 0
      ? String(Math.round(MetricsState.gpuUsage)).padStart(2, "0") + "%"
      : "--"
    detail: MetricsState.gpuVramTotalGb > 0
      ? MetricsState.gpuVramUsedGb.toFixed(1) + " / " + MetricsState.gpuVramTotalGb.toFixed(1) + "G"
      : "--"
    detail2: MetricsState.gpuTemp >= 0
      ? String(Math.round(MetricsState.gpuTemp)).padStart(2, "0") + "°C"
      : "--"
    height: root.graphCardHeight
    graphs: [
      {values: root.gpuUsageHistory, color: Wallust.base0B, label: "USE", maxValue: 100},
      {values: root.gpuVramHistory, color: Wallust.base0E, label: "VRAM", maxValue: MetricsState.gpuVramTotalGb > 0 ? MetricsState.gpuVramTotalGb : 16},
      {values: root.gpuTempHistory, color: Wallust.base08, label: "TMP", maxValue: 100}
    ]
  }

  MetricCard {
    id: memoryCard
    title: "MEMORY"
    value: MetricsState.memUsed >= 0 && MetricsState.memTotal >= 0
      ? MetricsState.memUsed.toFixed(1).padStart(4, "0") + " / " + MetricsState.memTotal.toFixed(1) + "G"
      : "--"
    height: root.graphCardHeight
    graphs: [
      {values: root.memUsageHistory, color: Wallust.accent, label: "USE", maxValue: 100},
      {values: root.memLoadHistory, color: Wallust.base0E, label: "LOAD", maxValue: MetricsState.memTotal > 0 ? MetricsState.memTotal : 32}
    ]
  }

  function pushHistory(arr, val) {
    return arr.concat([val]).slice(-maxHistory)
  }

  function sampleMetrics() {
    if (MetricsState.cpuUsage >= 0)
      root.cpuUsageHistory = root.pushHistory(root.cpuUsageHistory, MetricsState.cpuUsage)
    if (MetricsState.cpuTemp >= 0)
      root.cpuTempHistory = root.pushHistory(root.cpuTempHistory, MetricsState.cpuTemp)
    if (MetricsState.gpuUsage >= 0)
      root.gpuUsageHistory = root.pushHistory(root.gpuUsageHistory, MetricsState.gpuUsage)
    if (MetricsState.gpuVramUsedGb >= 0)
      root.gpuVramHistory = root.pushHistory(root.gpuVramHistory, MetricsState.gpuVramUsedGb)
    if (MetricsState.gpuTemp >= 0)
      root.gpuTempHistory = root.pushHistory(root.gpuTempHistory, MetricsState.gpuTemp)
    if (MetricsState.memPercent >= 0)
      root.memUsageHistory = root.pushHistory(root.memUsageHistory, MetricsState.memPercent)
    if (MetricsState.memUsed >= 0)
      root.memLoadHistory = root.pushHistory(root.memLoadHistory, MetricsState.memUsed)
  }

  onActiveChanged: {
    if (active) {
      MetricsState.refresh()
      sampleMetrics()
    }
  }

  Timer {
    interval: 3000
    running: root.active
    repeat: true
    onTriggered: root.sampleMetrics()
  }
}
