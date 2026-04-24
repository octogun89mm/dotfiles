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

  color: Wallust.base00
  implicitHeight: diskColumn.implicitHeight + 24

  function parseDiskValue(value) {
    const parsed = Number(value)
    return isNaN(parsed) ? NaN : parsed
  }

  function usageRatio(disk) {
    const used = parseDiskValue(disk.used)
    const total = parseDiskValue(disk.total)
    if (isNaN(used) || isNaN(total) || total <= 0) return 0
    return Math.max(0, Math.min(1, used / total))
  }

  function usageColor(ratio) {
    if (ratio >= 0.85) return Wallust.base08
    if (ratio >= 0.60) return Wallust.base0A
    return Wallust.base0B
  }

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
      font.family: "Iosevka"
      font.pixelSize: 10
      font.bold: true
    }

    Repeater {
      model: root.disks

      Row {
        required property var modelData
        width: diskColumn.width
        spacing: 6

        readonly property real ratio: root.usageRatio(modelData)
        readonly property color barColor: root.usageColor(ratio)

        Text {
          width: 50
          text: modelData.label
          elide: Text.ElideRight
          color: Wallust.base05
          font.family: "Iosevka"
          font.pixelSize: 10
        }

        Text {
          width: 88
          text: modelData.used.toString().padStart(3, "0") + " / " + modelData.total + "G"
          elide: Text.ElideRight
          color: Wallust.base05
          font.family: "Iosevka"
          font.pixelSize: 10
        }

        Rectangle {
          width: parent.width - 50 - 88 - parent.spacing * 2
          height: 10
          anchors.verticalCenter: parent.verticalCenter
          color: Wallust.base01
          border.width: 2
          border.color: Wallust.base02

          Rectangle {
            width: Math.max(0, parent.width - 4) * parent.parent.ratio
            height: Math.max(0, parent.height - 4)
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            color: parent.parent.barColor
          }
        }
      }
    }
  }
}
