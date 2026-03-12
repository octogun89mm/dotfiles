pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/waybar/scripts/expressvpn.sh"

  property bool connected: false
  property string icon: "󰒙"
  property string tooltip: "ExpressVPN is disconnected"
  property string statusText: "DISCONNECTED"
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
      const nextConnected = data.class === "vpn-connected"
      const changed = ready && nextConnected !== connected

      connected = nextConnected
      icon = data.alt || (connected ? "󰒘" : "󰒙")
      tooltip = data.tooltip || "ExpressVPN"
      statusText = connected ? "CONNECTED" : "DISCONNECTED"

      if (changed || pendingToggleFeedback) {
        OsdState.show(icon, "VPN " + statusText)
      }
    } catch (e) {
      console.warn("VpnState: failed to parse JSON:", e)
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
