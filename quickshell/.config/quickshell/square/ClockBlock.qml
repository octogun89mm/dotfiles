import QtQuick
import Quickshell

// HH:mm, bold.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: Qt.formatTime(clock.date, "HH:mm")
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
    font.bold: true
  }
}
