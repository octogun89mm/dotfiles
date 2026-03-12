pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/waybar/scripts/idle-inhibit.sh"

  property bool active: false
  property string icon: "󰈉"
  property string statusText: "NORMAL"
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
      icon = data.alt || (active ? "󰈈" : "󰈉")
      statusText = active ? "INHIBITED" : "NORMAL"

      if (changed || pendingToggleFeedback) {
        OsdState.show(icon, "IDLE " + statusText)
      }
    } catch (e) {
      console.warn("IdleState: failed to parse JSON:", e)
    }

    ready = true
    pendingToggleFeedback = false
  }

  Component.onCompleted: refreshStatus()

  FileView {
    path: "/tmp/idle-inhibit.pid"
    preload: true
    watchChanges: true
    printErrors: false

    onFileChanged: root.refreshStatus()
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
