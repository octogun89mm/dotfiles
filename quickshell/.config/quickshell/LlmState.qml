pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.local/bin/llama-toggle"

  property bool active: false
  property string icon: "󰧑"
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
      const nextActive = data.class === "activated"
      const changed = ready && nextActive !== active

      active = nextActive
      icon = data.alt || "󰧑"
      statusText = active ? "ON" : "OFF"

      if (changed || pendingToggleFeedback) {
        OsdState.show(icon, "LLM " + statusText)
      }
    } catch (e) {
      console.warn("LlmState: failed to parse JSON:", e)
    }

    ready = true
    pendingToggleFeedback = false
  }

  Component.onCompleted: refreshStatus()

  FileView {
    path: "/tmp/llama-toggle.state"
    preload: true
    watchChanges: true
    printErrors: false

    onFileChanged: root.refreshStatus()
  }

  Timer {
    interval: 30000
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
