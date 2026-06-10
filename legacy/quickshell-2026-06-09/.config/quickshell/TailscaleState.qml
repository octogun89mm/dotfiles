pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/tailscale.sh"

  property bool connected: false
  property string icon: "󰖃"
  property string tooltip: "Tailscale is stopped"
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
      const nextConnected = data.class === "tailscale-connected"
      const changed = ready && nextConnected !== connected

      connected = nextConnected
      icon = data.alt || (connected ? "󰖂" : "󰖃")
      tooltip = data.tooltip || "Tailscale"
      statusText = connected ? "ON" : "OFF"

      if (changed || pendingToggleFeedback) {
        OsdState.show(icon, "TAILSCALE " + statusText)
      }
    } catch (e) {
      console.warn("TailscaleState: failed to parse JSON:", e)
    }

    ready = true
    pendingToggleFeedback = false
  }

  Component.onCompleted: refreshStatus()

  Timer {
    interval: 10000
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
