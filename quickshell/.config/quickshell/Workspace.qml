import QtQuick
import Quickshell.Hyprland
import "wallust.js" as Wallust

Row {
  function workspacePriority(workspace) {
    if (workspace.name === "special:dropdown") return 2
    if (workspace.name.startsWith("special:")) return 1
    return 0
  }

  function displayNameFor(workspace) {
    if (workspace.name === "special:dropdown") return "="
    if (workspace.name === "special:magic") return "-"
    if (workspace.name.startsWith("special:")) return workspace.name.slice("special:".length)
    return workspace.name
  }

  function monitorKey(workspace) {
    const m = workspace.monitor
    if (!m) return ""
    return m.name || String(m.id || "")
  }

  property var entries: {
    const sorted = Hyprland.workspaces.values
      .slice()
      .filter(ws => ws.toplevels.values.length > 0 || ws.focused)
      .sort((a, b) => {
        const priorityDelta = workspacePriority(a) - workspacePriority(b)
        if (priorityDelta !== 0) return priorityDelta
        return a.id - b.id
      })

    const result = []
    let lastMonitor = null
    for (let i = 0; i < sorted.length; i++) {
      const ws = sorted[i]
      const mk = monitorKey(ws)
      if (lastMonitor !== null && mk !== lastMonitor) {
        result.push({ kind: "sep" })
      }
      result.push({ kind: "ws", workspace: ws })
      lastMonitor = mk
    }
    return result
  }

  spacing: 8

  Repeater {
    model: entries

    Loader {
      required property var modelData
      sourceComponent: modelData.kind === "sep" ? sepComponent : wsComponent

      Component {
        id: wsComponent
        WorkspaceChip {
          workspace: modelData.workspace
          displayName: displayNameFor(modelData.workspace)
        }
      }

      Component {
        id: sepComponent
        Item {
          implicitWidth: 1
          implicitHeight: 20
          Rectangle {
            anchors.centerIn: parent
            width: 1
            height: 10
            color: Wallust.base02
            opacity: 0.6
          }
        }
      }
    }
  }
}
