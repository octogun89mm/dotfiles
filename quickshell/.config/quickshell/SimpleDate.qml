import QtQuick
import Quickshell
import "wallust.js" as Wallust

Item {
  id: root

  property bool hovered: dateMouse.containsMouse
  property bool pinned: false

  signal clicked

  implicitWidth: dateLabel.implicitWidth
  implicitHeight: 20

  Text {
    id: dateLabel
    anchors.centerIn: parent
    text: Qt.formatDate(clock.date, "ddd-dd-MM-yy")
    color: root.pinned ? Wallust.accent : Wallust.base05
    font.family: "Iosevka"
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
