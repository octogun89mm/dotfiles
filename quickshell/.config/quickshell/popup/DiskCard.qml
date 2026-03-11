import QtQuick
import Quickshell.Io
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property bool active: false
  property var disks: []

  color: Wallust.base01
  implicitWidth: 320
  implicitHeight: diskColumn.implicitHeight + 24

  function refreshDisk() {
    diskProcess.exec(["/bin/bash", "-c", "df -BG / /mnt/*/ 2>/dev/null | awk 'NR>1 && !seen[$1]++ {gsub(/G/,\"\",$2); gsub(/G/,\"\",$3); print $6 \"|\" $3 \"|\" $2}'"])
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
        const lines = text.trim().split("\n")
        const result = []
        for (const line of lines) {
          const parts = line.split("|")
          if (parts.length === 3) {
            const mount = parts[0]
            const used = parts[1]
            const total = parts[2]
            const label = mount === "/" ? "Main" : mount.split("/").pop()
            result.push({ label: label, used: used, total: total })
          }
        }
        root.disks = result
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
          text: modelData.used.padStart(3, "0") + " / " + modelData.total + "G"
          color: Wallust.base05
          font.family: "Roboto Mono"
          font.pixelSize: 10
        }
      }
    }
  }
}
