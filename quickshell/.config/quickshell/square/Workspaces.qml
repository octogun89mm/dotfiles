import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// All nine workspaces, always visible, grouped by monitor (wider gap
// between groups), monochrome and text-first. Exactly one understripe
// per monitor (its active workspace), so any single bar is a complete
// map of every monitor without colour coding.
//   bold + bright stripe = where the keyboard focus is
//   bright + dim stripe  = active workspace of another monitor
//   muted text           = occupied, inactive
//   dim text             = empty
//   critical             = urgent
Row {
  id: root

  spacing: 0
  property var workspaceWindows: ({})
  property var appIconEntries: []

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()

      const name = event.name
      if (name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "movewindowv2") {
        root.refreshClients()
      }
    }
  }

  // Mirrors the workspace->monitor rules in hyprland.conf:
  // 1,2,3 -> HDMI-A-1 | 4,5,6 -> DP-2 | 7,8,9 -> DP-1
  readonly property var wsGroups: [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  readonly property var cells: {
    const out = []
    for (let g = 0; g < wsGroups.length; g++)
      for (let i = 0; i < wsGroups[g].length; i++)
        out.push({ id: wsGroups[g][i], newGroup: g > 0 && i === 0 })
    return out
  }

  readonly property var liveWorkspaces: Hyprland.workspaces.values
  readonly property var liveMonitors: Hyprland.monitors.values

  function appKeyForClient(client) {
    return String(client.class || client.title || "")
  }

  function iconsForWorkspace(workspaceId) {
    const apps = workspaceWindows[workspaceId] || []
    const counts = {}
    const compact = []

    for (let i = 0; i < apps.length; i++) {
      const icon = iconForApp(apps[i])
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

    return compact.slice(0, 3)
  }

  function iconForApp(text) {
    const key = String(text || "").toLowerCase()
    if (!key) return ""

    for (let i = 0; i < appIconEntries.length; i++) {
      const entry = appIconEntries[i]
      const patterns = entry.patterns || []
      for (let j = 0; j < patterns.length; j++) {
        if (key.indexOf(patterns[j]) !== -1) return entry.icon || ""
      }
    }

    return ""
  }

  function loadAppIcons(text) {
    try {
      const data = JSON.parse(text || "[]")
      appIconEntries = Array.isArray(data) ? data : []
      refreshClients()
    } catch (e) {
      appIconEntries = []
    }
  }

  function isVisibleWorkspace(workspaceId) {
    for (let i = 0; i < liveMonitors.length; i++) {
      const activeWorkspace = liveMonitors[i].activeWorkspace
      if (activeWorkspace && activeWorkspace.id === workspaceId)
        return true
    }

    return false
  }

  function refreshClients() {
    refreshTimer.restart()
  }

  Timer {
    id: refreshTimer
    interval: 120
    repeat: false
    onTriggered: {
      if (!clientsProcess.running) clientsProcess.exec(["hyprctl", "clients", "-j"])
    }
  }

  Timer {
    id: delayedRefreshTimer
    interval: 800
    repeat: false
    onTriggered: root.refreshClients()
  }

  Component.onCompleted: {
    refreshClients()
    delayedRefreshTimer.start()
  }

  Repeater {
    model: root.cells

    Item {
      id: cell
      required property var modelData
      readonly property var ws: root.liveWorkspaces.find(w => w.id === modelData.id) ?? null
      readonly property bool active: root.isVisibleWorkspace(modelData.id)
      readonly property bool focused: ws ? ws.focused : false
      readonly property bool urgent: ws ? ws.urgent === true : false
      readonly property bool occupied: ws ? ws.toplevels.values.length > 0 : false
      readonly property var windowIcons: root.iconsForWorkspace(modelData.id)
      readonly property int groupGap: modelData.newGroup ? Theme.padLg : 0
      readonly property int chipWidth: Math.max(18, content.implicitWidth + Theme.padSm * 2)
        + (focused ? Theme.padMd : active ? Theme.padSm : 0)

      implicitWidth: cell.groupGap + cell.chipWidth
      implicitHeight: Theme.barHeight

      Behavior on implicitWidth {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        x: cell.groupGap + Math.round((cell.chipWidth - implicitWidth) / 2)
        spacing: 3

        Behavior on x {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Text {
          id: label
          anchors.verticalCenter: parent.verticalCenter
          text: String(cell.modelData.id)
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSm
          font.bold: cell.focused
          color: cell.urgent ? Theme.critical
            : (cell.focused || cell.active) ? Theme.text
            : cell.occupied ? Theme.textMuted
            : Theme.textDim

          Behavior on color {
            ColorAnimation { duration: Theme.animFast }
          }
        }

        Repeater {
          model: cell.windowIcons

          Item {
            required property var modelData
            readonly property color iconColor: cell.focused || cell.active ? Theme.text : Theme.textMuted
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: iconLabel.implicitWidth + (countLabel.visible ? countLabel.implicitWidth + 1 : 0)
            implicitHeight: Math.max(iconLabel.implicitHeight, countLabel.visible ? countLabel.implicitHeight + 1 : 0)

            Text {
              id: iconLabel
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.icon
              color: parent.iconColor
              font.family: Theme.iconFamily
              font.pixelSize: 10
            }

            Text {
              id: countLabel
              anchors.left: iconLabel.right
              anchors.leftMargin: 1
              anchors.top: parent.top
              anchors.topMargin: -2
              visible: modelData.count > 1
              text: modelData.count
              color: parent.iconColor
              font.family: Theme.fontFamily
              font.pixelSize: 8
              font.bold: true
            }
          }
        }
      }

      Rectangle {
        visible: cell.active || cell.urgent
        anchors.bottom: parent.bottom
        x: cell.groupGap
        width: cell.chipWidth
        height: Theme.stripe + 1
        color: cell.urgent ? Theme.critical
          : cell.focused ? Theme.text
          : Theme.textDim

        Behavior on color {
          ColorAnimation { duration: Theme.animFast }
        }

        Behavior on x {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Behavior on width {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + cell.modelData.id)
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
              next[workspaceId].push(root.appKeyForClient(client))
            }
          }
          root.workspaceWindows = next
        } catch (e) {
          root.workspaceWindows = ({})
        }
      }
    }
  }

  FileView {
    path: "/home/juju/.dotfiles/quickshell/.config/quickshell/window-icons/apps.json"
    watchChanges: true
    onLoaded: root.loadAppIcons(text())
    onFileChanged: {
      reload()
      root.loadAppIcons(text())
    }
  }
}
