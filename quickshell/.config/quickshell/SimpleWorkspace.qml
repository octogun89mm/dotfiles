import QtQuick
import Quickshell.Hyprland

Item {
  id: root
  implicitWidth: workspaceRow.implicitWidth
  implicitHeight: Theme.chipHeight

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

  property int refreshTick: 0

  property var entries: {
    refreshTick
    const result = []
    for (let i = 1; i <= 6; i++) {
      result.push({ kind: "ws", id: i })
    }
    return result
  }

  Connections {
    target: Hyprland
    function onRawEvent() {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
      root.refreshTick++
    }
  }

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
      }
    }
  }
}
