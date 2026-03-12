import QtQuick
import Quickshell
import Quickshell.Io
import "../wallust.js" as Wallust

Rectangle {
  id: root
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string diskScript: home + "/.dotfiles/quickshell/.config/quickshell/scripts/disk-usage.sh"

  property bool active: false
  property var disks: []

  color: Wallust.base03
  implicitWidth: 320
  implicitHeight: diskColumn.implicitHeight + 24

  function refreshDisk() {
    diskProcess.exec([diskScript])
  }

  onActiveChanged: if (active) refreshDisk()

  Timer {
    interval: 60000
    running: root.active
    repeat: true
    onTriggered: root.refreshDisk()
  }

  Process {
    id: diskProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim()) return
        try {
          const data = JSON.parse(text)
          root.disks = Array.isArray(data) ? data : []
        } catch (e) {
          console.warn("DiskCard: failed to parse JSON:", e)
        }
      }
    }
  }

  Column {
    id: diskColumn
    anchors.fill: parent
    anchors.margins: 12
    spacing: 4

    Text {
      text: "DISK"
      color: Wallust.base04
      font.family: "Roboto Mono"
      font.pixelSize: 10
      font.bold: true
    }

    Repeater {
      model: root.disks

      Row {
        required property var modelData
        width: diskColumn.width
        spacing: 6

        Text {
          width: 50
          text: modelData.label
          elide: Text.ElideRight
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 10
        }

        Text {
          text: modelData.used.toString().padStart(3, "0") + " / " + modelData.total + "G"
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 10
        }
      }
    }
  }
}
