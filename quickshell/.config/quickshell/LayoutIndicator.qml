import QtQuick
import Quickshell
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  required property string monitorName
  required property string monitorId
  property bool compact: false
  property bool borderless: true
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string cycleScript: home + "/.dotfiles/rust-tools/target/release/cycle-layout"
  readonly property string layoutScript: home + "/.dotfiles/rust-tools/target/release/bar-window-count"
  readonly property string refreshStamp: "/tmp/quickshell-layout-refresh.state"
  property string layout: "MASTER"

  function refreshLayout() {
    statusProcess.exec([root.layoutScript, root.monitorName])
  }

  color: "transparent"
  implicitWidth: layoutMetrics.width + Theme.padSm * 2
  implicitHeight: Theme.chipHeight

  function normalizedLayout(value) {
    return (value || "").trim().toUpperCase()
  }

  function stripeColor(value) {
    switch (normalizedLayout(value)) {
    case "MASTER":   return Theme.accent
    case "DWINDLE":  return Theme.success
    case "SCROLLING": return Wallust.base0E
    case "MONOCLE":  return Theme.warning
    default:         return Theme.border
    }
  }

  function layoutLabel(value) {
    return normalizedLayout(value)
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    spacing: 0

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.layoutLabel(root.layout)
      width: layoutMetrics.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      color: root.stripeColor(root.layout)
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
      font.bold: true
      font.letterSpacing: 0.6

      Behavior on color {
        ColorAnimation { duration: 220; easing.type: Easing.InOutSine }
      }
    }
  }

  TextMetrics {
    id: layoutMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    font.letterSpacing: 0.6
    text: "SCROLLING"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: cycleProcess.exec([root.cycleScript])
  }

  Process {
    id: statusProcess

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!text || !text.trim())
          return

        try {
          const data = JSON.parse(text)
          root.layout = root.normalizedLayout(data.layout || text)
        } catch (_) {
          root.layout = root.normalizedLayout(text)
        }
      }
    }
  }

  Component.onCompleted: refreshLayout()

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refreshLayout()
  }

  FileView {
    path: root.refreshStamp
    preload: true
    watchChanges: true
    printErrors: false

    onFileChanged: root.refreshLayout()
  }

  Process {
    id: cycleProcess
    onExited: root.refreshLayout()
  }
}
