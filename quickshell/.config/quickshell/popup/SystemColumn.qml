import QtQuick
import Quickshell.Io

Column {
  id: root

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

  spacing: 10

  MetricCard {
    title: "CPU"
    value: root.cpuUsage.padStart(2, "0") + "%"
    detail: root.cpuTemp.padStart(2, "0") + "°C"
  }

  MetricCard {
    title: "GPU"
    value: root.gpuUsage.padStart(2, "0") + "%"
    detail: root.gpuVramUsed + " / " + root.gpuVramTotal + "G"
    detail2: root.gpuTemp.padStart(2, "0") + "°C"
  }

  MetricCard {
    title: "MEMORY"
    value: root.memoryUsed.padStart(4, "0") + " / " + root.memoryTotal + "G"
  }

  MetricCard {
    title: "UPDATES"
    value: root.updates.padStart(3, "0")
  }

  function refreshCpu() {
    cpuUsageProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "cpu-usage"])
    cpuTempProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "cpu-temp"])
  }

  function refreshMemory() {
    memoryUsedProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "memory-used"])
    memoryTotalProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "memory-total"])
  }

  function refreshUpdates() {
    updatesProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "updates"])
  }

  function refreshGpu() {
    gpuProcess.exec(["/home/juju/.dotfiles/eww/.config/eww/scripts/eww-bar", "gpu"])
  }

  onActiveChanged: {
    if (active) {
      refreshCpu()
      refreshMemory()
      refreshUpdates()
      refreshGpu()
    }
  }

  Timer {
    interval: 3000
    running: root.active
    repeat: true
    onTriggered: {
      root.refreshCpu()
      root.refreshGpu()
    }
  }

  Timer {
    interval: 5000
    running: root.active
    repeat: true
    onTriggered: root.refreshMemory()
  }

  Timer {
    interval: 60000
    running: root.active
    repeat: true
    onTriggered: root.refreshUpdates()
  }

  Process {
    id: cpuUsageProcess
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.cpuUsage = text.trim() || "--" }
  }

  Process {
    id: cpuTempProcess
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.cpuTemp = text.trim() || "--" }
  }

  Process {
    id: memoryUsedProcess
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.memoryUsed = text.trim() || "--" }
  }

  Process {
    id: memoryTotalProcess
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.memoryTotal = text.trim() || "--" }
  }

  Process {
    id: updatesProcess
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updates = text.trim() || "--" }
  }

  Process {
    id: gpuProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        const data = JSON.parse(text)
        root.gpuUsage = data.usage || "--"
        root.gpuTemp = data.temp || "--"
        const used = parseFloat(data.vram_used || 0)
        root.gpuVramUsed = used.toFixed(1).padStart(4, "0")
        root.gpuVramTotal = data.vram_total || "--"
      }
    }
  }
}
