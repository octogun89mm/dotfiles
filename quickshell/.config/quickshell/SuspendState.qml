pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/hypr/scripts/hypridle-suspend.sh"
  readonly property string statePath: home + "/.local/state/hypridle-suspend-disabled"

  property bool enabled: true
  property string icon: "󰒲"
  property string statusText: "ON"
  property bool ready: false
  property bool pendingToggleFeedback: false

  function refreshStatus() {
    statusProcess.exec([scriptPath, "status"])
  }

  function toggle() {
    pendingToggleFeedback = true
    toggleProcess.exec([scriptPath, "toggle"])
  }

  function parseStatus(text) {
    if (!text || !text.trim()) return

    try {
      const data = JSON.parse(text)
      const nextEnabled = data.active !== false
      const changed = ready && nextEnabled !== enabled

      enabled = nextEnabled
      statusText = enabled ? "ON" : "OFF"

      if (changed || pendingToggleFeedback) {
        OsdState.show(icon, "SUSPEND " + statusText)
      }
    } catch (e) {
      console.warn("SuspendState: failed to parse JSON:", e)
    }

    ready = true
    pendingToggleFeedback = false
  }

  Component.onCompleted: refreshStatus()

  FileView {
    path: root.statePath
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
