pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polls interface name + wifi signal via the shared network-status.sh helper.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string scriptPath: home + "/.config/quickshell/scripts/network-status.sh"

  property string iface: ""
  property int signal: 0

  readonly property bool connected: iface.length > 0
  readonly property bool isWifi: iface.startsWith("wl")

  readonly property string icon: {
    if (!connected) return "󰈂"
    if (isWifi) {
      if (signal >= 75) return "󰤨"
      if (signal >= 50) return "󰤥"
      if (signal >= 25) return "󰤢"
      return "󰤟"
    }
    return "󰈀"
  }

  function refresh() {
    if (networkProc.running) return
    networkProc.exec([scriptPath])
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: networkProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        try {
          const data = JSON.parse(text.trim())
          root.iface = String(data.iface || "")
          root.signal = Math.max(0, Math.min(100, Number(data.signal || 0)))
        } catch (e) {
          console.warn("NetworkState: failed to parse:", e)
        }
      }
    }
  }
}
