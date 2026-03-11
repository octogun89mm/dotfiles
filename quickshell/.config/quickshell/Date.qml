import QtQuick
import Quickshell
import "wallust.js" as Wallust

Rectangle {
  id: root

  property bool hovered: dateMouse.containsMouse
  property bool pinned: false

  signal clicked

  color: pinned ? Wallust.base0E : Wallust.base0D
  implicitWidth: dateLabel.implicitWidth + 10
  implicitHeight: 24

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
