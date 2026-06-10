import QtQuick
import Quickshell

// ddd dd MMM, uppercase, textMuted.
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
    text: Qt.formatDate(clock.date, "ddd dd MMM").toUpperCase()
    color: Theme.textMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
    font.letterSpacing: 0.5
  }
}
