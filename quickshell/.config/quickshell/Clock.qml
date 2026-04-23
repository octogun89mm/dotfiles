import QtQuick
import Quickshell
import "wallust.js" as Wallust

Rectangle {
  id: root

  property bool hovered: clockMouse.containsMouse
  property bool pinned: false

  signal clicked

  color: pinned ? Wallust.base0E : Wallust.accent
  implicitWidth: clockLabel.implicitWidth + 10
  implicitHeight: clockLabel.implicitHeight + 4

  Text {
    id: clockLabel
    anchors.centerIn: parent
    text: Qt.formatTime(clock.date, "hh:mm AP")
    color: Wallust.base00
    font.family: "Iosevka"
    font.pixelSize: 14
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
