import QtQuick
import Quickshell.Hyprland

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

  property var orderedWorkspaces: Hyprland.workspaces.values
    .slice()
    .filter(workspace => workspace.toplevels.values.length > 0 || workspace.focused)
    .sort((a, b) => {
      const priorityDelta = workspacePriority(a) - workspacePriority(b)

      if (priorityDelta !== 0) return priorityDelta

      return a.id - b.id
    })

  spacing: 8

  Repeater {
    model: orderedWorkspaces

    WorkspaceChip {
      required property var modelData
      workspace: modelData
      displayName: displayNameFor(workspace)
    }
  }
}
