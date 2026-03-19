import QtQuick
import Quickshell.Hyprland
import Quickshell
import Quickshell.Io
import "wallust.js" as Wallust

Item {
  id: root

  required property string monitorName
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string countScript: home + "/.dotfiles/quickshell/.config/quickshell/scripts/bar_window_count.sh"
  property int windowCount: 0
  property string layoutName: ""

  function refreshState() {
    countProcess.exec([countScript, monitorName])
  }

  implicitWidth: cluster.implicitWidth
  implicitHeight: 20
  visible: true

  Row {
    id: cluster
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    Text {
      id: countLabel
      anchors.verticalCenter: parent.verticalCenter
      text: String(root.windowCount).padStart(2, "0")
      color: Wallust.base04
      font.family: "Roboto Mono"
      font.pixelSize: 11
      font.bold: true
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 1
      height: 12
      color: Wallust.base02
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent() {
      root.refreshState()
    }
  }

  Component.onCompleted: refreshState()

  Process {
    id: countProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (!text || !text.trim())
          return

        try {
          const data = JSON.parse(text.trim())
          root.windowCount = Number(data.count || 0)
          root.layoutName = String(data.layout || "").trim().toUpperCase()
        } catch (error) {
          root.windowCount = 0
          root.layoutName = ""
        }
      }
    }
  }
}
