import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root
  implicitWidth: workspaceRow.implicitWidth
  implicitHeight: Theme.chipHeight
  property var workspaceWindows: ({})

  function monitorKeyFor(id) {
    const workspaces = Hyprland.workspaces.values
    for (let i = 0; i < workspaces.length; i++) {
      if (workspaces[i].id === id) {
        const m = workspaces[i].monitor
        if (m) return m.name || String(m.id || "")
        return ""
      }
    }

    const monitors = Hyprland.monitors.values
    for (let i = 0; i < monitors.length; i++) {
      const aw = monitors[i].activeWorkspace
      if (aw && aw.id === id) return monitors[i].name
    }

    return ""
  }

  property var entries: [
    { kind: "ws", id: 1 },
    { kind: "ws", id: 2 },
    { kind: "ws", id: 3 },
    { kind: "ws", id: 4 },
    { kind: "ws", id: 5 },
    { kind: "ws", id: 6 }
  ]

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      const name = event.name
      if (name === "workspace"
          || name === "workspacev2"
          || name === "focusedmon"
          || name === "focusedmonv2"
          || name === "createworkspace"
          || name === "createworkspacev2"
          || name === "destroyworkspace"
          || name === "destroyworkspacev2"
          || name === "moveworkspace"
          || name === "moveworkspacev2"
          || name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "movewindowv2") {
        hyprRefreshTimer.restart()
      }

      if (name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "movewindowv2") {
        root.refreshClients()
      }
    }
  }

  Timer {
    id: hyprRefreshTimer
    interval: 50
    repeat: false
    onTriggered: {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  function iconForClient(client) {
    return WindowIcons.iconForApp(String(client.class || client.title || ""))
  }

  function iconsForWorkspace(workspaceId) {
    const icons = workspaceWindows[workspaceId] || []
    const counts = {}
    const compact = []

    for (let i = 0; i < icons.length; i++) {
      const icon = icons[i]
      if (!icon) continue
      if (!counts[icon]) {
        counts[icon] = 0
        compact.push({ icon: icon, count: 0 })
      }
      counts[icon] += 1
    }

    for (let i = 0; i < compact.length; i++) {
      compact[i].count = counts[compact[i].icon]
    }

    return compact.slice(0, 4)
  }

  function refreshClients() {
    refreshTimer.restart()
  }

  Timer {
    id: refreshTimer
    interval: 150
    repeat: false
    onTriggered: {
      if (!clientsProcess.running) clientsProcess.exec(["hyprctl", "clients", "-j"])
    }
  }

  Component.onCompleted: refreshClients()

  Row {
    id: workspaceRow
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Repeater {
      model: root.entries

      SimpleWorkspaceChip {
        required property var modelData
        workspaceId: modelData.id
        displayName: String(modelData.id)
        windowIcons: root.iconsForWorkspace(modelData.id)
      }
    }
  }

  Process {
    id: clientsProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) {
          root.workspaceWindows = ({})
          return
        }

        try {
          const clients = JSON.parse(text)
          const next = {}
          if (Array.isArray(clients)) {
            for (let i = 0; i < clients.length; i++) {
              const client = clients[i]
              const workspaceId = client.workspace && typeof client.workspace.id === "number" ? client.workspace.id : 0
              if (workspaceId < 1) continue
              if (!next[workspaceId]) next[workspaceId] = []
              next[workspaceId].push(root.iconForClient(client))
            }
          }
          root.workspaceWindows = next
        } catch (e) {
          root.workspaceWindows = ({})
        }
      }
    }
  }
}
