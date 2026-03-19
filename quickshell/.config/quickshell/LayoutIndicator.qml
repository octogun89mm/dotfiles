import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  required property string monitorName
  required property string monitorId
  property bool compact: false
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string cycleScript: home + "/.config/hypr/scripts/cycle-layout.sh"
  readonly property string layoutScript: home + "/.dotfiles/quickshell/.config/quickshell/scripts/bar_layout.sh"
  readonly property string refreshStamp: "/tmp/quickshell-layout-refresh.state"
  property string layout: "MASTER"
  readonly property int edgeWidth: 2

  function refreshLayout() {
    statusProcess.exec([root.layoutScript, root.monitorName])
  }

  color: backgroundColor(layout)
  implicitWidth: compact ? layoutLabel.implicitWidth + 8 : 28
  implicitHeight: compact ? 20 : 24

  Rectangle {
    visible: !root.compact
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
    visible: !root.compact
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
    visible: !root.compact
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.edgeWidth
    color: Wallust.base03
  }

  function normalizedLayout(value) {
    return (value || "").trim().toUpperCase()
  }

  function backgroundColor(value) {
    switch (normalizedLayout(value)) {
    case "MASTER":
      return Wallust.accent
    case "DWINDLE":
      return Wallust.base0B
    case "SCROLLING":
      return Wallust.base0E
    case "MONOCLE":
      return Wallust.base0A
    default:
      return Wallust.base03
    }
  }

  function iconSource(value) {
    switch (normalizedLayout(value)) {
    case "MASTER":
      return "ressources/layout-icons/layout-master.svg"
    case "DWINDLE":
      return "ressources/layout-icons/layout-dwindle.svg"
    case "SCROLLING":
      return "ressources/layout-icons/layout-scrolling.svg"
    case "MONOCLE":
      return "ressources/layout-icons/layout-monocle.svg"
    default:
      return ""
    }
  }

  Text {
    id: layoutLabel
    anchors.centerIn: parent
    visible: root.compact
    text: root.normalizedLayout(root.layout).slice(0, 3)
    color: Wallust.base00
    font.family: "Roboto Mono"
    font.pixelSize: 11
    font.bold: true
  }

  Image {
    id: iconImage
    anchors.centerIn: parent
    width: 16
    height: 16
    source: root.iconSource(root.layout)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: !root.compact
  }

  MultiEffect {
    visible: !root.compact
    anchors.fill: iconImage
    source: iconImage
    colorization: 1.0
    colorizationColor: Wallust.background
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
