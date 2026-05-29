pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/jubotai-convo.sh"

  property bool on: false
  property bool partial: false
  property string icon: "󰭹"
  property string tooltip: "JuBotAI-Convo is off"
  property string statusText: "OFF"
  property bool ready: false
  property bool pendingToggleFeedback: false

  function refreshStatus() {
    statusProcess.exec([scriptPath])
  }

  function toggle() {
    pendingToggleFeedback = true
    toggleProcess.exec([scriptPath, "toggle"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return

    try {
      const data = JSON.parse(text)
      on = data.class === "jubotai-on"
      partial = data.class === "jubotai-partial"
      icon = data.alt || "󰭹"
      tooltip = data.tooltip || "JuBotAI-Convo"
      statusText = data.text || (on ? "ON" : (partial ? "HALF" : "OFF"))
    } catch (e) {
      console.warn("JubotaiConvoState: failed to parse JSON:", e)
    }

    ready = true
    pendingToggleFeedback = false
  }

  Component.onCompleted: refreshStatus()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStatus(text)
    }
  }

  Process {
    id: toggleProcess
    onExited: root.refreshStatus()
  }
}
