import QtQuick
import Quickshell.Hyprland
import Quickshell
import Quickshell.Io

Item {
  id: root

  required property string monitorName
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string countScript: home + "/.dotfiles/rust-tools/target/release/bar-window-count"
  property int windowCount: 0
  property string layoutName: ""

  function refreshState() {
    countProcess.exec([countScript, monitorName])
  }

  implicitWidth: countMetrics.width + winMetrics.width + Theme.padSm + Theme.padMd
  implicitHeight: Theme.chipHeight
  visible: true

  Row {
    id: cluster
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(root.windowCount).padStart(2, "0")
      width: countMetrics.width
      horizontalAlignment: Text.AlignRight
      color: root.windowCount > 0 ? Theme.text : Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSmall
      font.bold: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "WIN"
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
      font.letterSpacing: 0.5
    }
  }

  TextMetrics {
    id: countMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
    font.bold: true
    text: "000"
  }

  TextMetrics {
    id: winMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.letterSpacing: 0.5
    text: "WIN"
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      const name = event.name
      if (name === "workspace"
          || name === "workspacev2"
          || name === "focusedmon"
          || name === "focusedmonv2"
          || name === "openwindow"
          || name === "closewindow"
          || name === "movewindow"
          || name === "movewindowv2") {
        root.refreshState()
      }
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
