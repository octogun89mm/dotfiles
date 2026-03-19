import QtQuick
import Quickshell
import "wallust.js" as Wallust

Rectangle {
  id: root

  property bool hovered: dateMouse.containsMouse
  property bool pinned: false
  readonly property int edgeWidth: 2

  signal clicked

  color: pinned ? Wallust.base0E : Wallust.accent
  implicitWidth: dateLabel.implicitWidth + 10
  implicitHeight: 24

  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.edgeWidth
    color: Wallust.base03
  }

  Rectangle {
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: root.edgeWidth
    color: Wallust.base03
  }

  Text {
    id: dateLabel
    anchors.centerIn: parent
    text: Qt.formatDate(clock.date, "ddd-dd-MM-yy")
    color: Wallust.base00
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  MouseArea {
    id: dateMouse
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
