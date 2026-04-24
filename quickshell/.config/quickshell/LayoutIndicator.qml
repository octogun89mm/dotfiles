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
  readonly property string cycleScript: home + "/.config/hypr/scripts/cycle-layout.sh"
  readonly property string layoutScript: home + "/.dotfiles/quickshell/.config/quickshell/scripts/bar_layout.sh"
  readonly property string refreshStamp: "/tmp/quickshell-layout-refresh.state"
  property string layout: "MASTER"

  function refreshLayout() {
    statusProcess.exec([root.layoutScript, root.monitorName])
  }

  color: "transparent"
  implicitWidth: row.implicitWidth + Theme.padMd + Theme.stripe
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

  function shortLabel(value) {
    switch (normalizedLayout(value)) {
    case "MASTER":   return "MAS"
    case "DWINDLE":  return "DWI"
    case "SCROLLING": return "SCR"
    case "MONOCLE":  return "MON"
    default:         return normalizedLayout(value).slice(0, 3)
    }
  }

  // Left accent stripe, colored per layout
  Rectangle {
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: Theme.stripe
    color: root.stripeColor(root.layout)

    Behavior on color {
      ColorAnimation { duration: 220; easing.type: Easing.InOutSine }
    }
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.stripe + Theme.padSm
    spacing: 0

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.shortLabel(root.layout)
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
      font.bold: true
      font.letterSpacing: 0.6
    }
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

        root.layout = root.normalizedLayout(text)
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
