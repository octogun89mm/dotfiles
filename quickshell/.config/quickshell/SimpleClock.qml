import QtQuick
import Quickshell
import "wallust.js" as Wallust

Item {
  id: root

  property bool hovered: clockMouse.containsMouse
  property bool pinned: false

  signal clicked

  implicitWidth: clockLabel.implicitWidth
  implicitHeight: 20

  Text {
    id: clockLabel
    anchors.centerIn: parent
    text: Qt.formatTime(clock.date, "hh:mm AP")
    color: root.pinned ? Wallust.accent : Wallust.base05
    font.family: "Roboto Mono"
    font.pixelSize: 13
    font.bold: true
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  MouseArea {
    id: clockMouse
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
