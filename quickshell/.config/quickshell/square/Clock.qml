import QtQuick
import Quickshell

// "ddd dd" Theme.textMuted, a dim dot, then "h:mm AP" bold — centered
// in the bar.
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
    spacing: Theme.padMd

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDate(clock.date, "ddd MMM dd")
      color: Theme.textMuted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "·"
      color: Theme.textDim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatTime(clock.date, "h:mm AP")
      color: Theme.text
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontMd
      font.bold: true
    }
  }
}
