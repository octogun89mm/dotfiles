import QtQuick
import Quickshell

// "HH:mm" bold Theme.text, followed by "ddd dd" Theme.textMuted.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.padSm

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatTime(clock.date, "HH:mm")
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
      font.bold: true
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDate(clock.date, "ddd dd")
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }
  }
}
