import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "wallust.js" as Wallust

Rectangle {
  id: root

  required property string monitorName
  required property string monitorId
  property string layout: "MASTER"
  readonly property int edgeWidth: 2

  color: backgroundColor(layout)
  implicitWidth: 28
  implicitHeight: 24

  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
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
      return Wallust.base0D
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
      return "ressources/layout-icons/layout-master.png"
    case "DWINDLE":
      return "ressources/layout-icons/layout-dwindle.png"
    case "SCROLLING":
      return "ressources/layout-icons/layout-scrolling.png"
    case "MONOCLE":
      return "ressources/layout-icons/layout-monocle.png"
    default:
      return ""
    }
  }

  Image {
    id: iconImage
    anchors.centerIn: parent
    width: 16
    height: 16
    source: root.iconSource(root.layout)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: false
  }

  MultiEffect {
    anchors.fill: iconImage
    source: iconImage
    colorization: 1.0
    colorizationColor: Wallust.background
  }

  MouseArea {
    anchors.fill: parent
    onClicked: cycleProcess.exec(["/home/juju/.config/hypr/scripts/cycle-layout.sh"])
  }

  Process {
    command: ["/home/juju/.dotfiles/quickshell/.config/quickshell/scripts/bar_layout.sh", root.monitorName, root.monitorId]
    running: true

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(data) {
        if (!data || !data.trim()) return
        root.layout = root.normalizedLayout(data)
      }
    }
  }

  Process {
    id: cycleProcess
  }
}
