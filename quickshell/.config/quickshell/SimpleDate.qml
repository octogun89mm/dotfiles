import QtQuick
import Quickshell

Item {
  id: root

  property bool hovered: dateMouse.containsMouse
  property bool pinned: false

  signal clicked

  implicitWidth: dateLabel.implicitWidth + Theme.padMd * 2
  implicitHeight: Theme.chipHeight

  Text {
    id: dateLabel
    anchors.centerIn: parent
    text: Qt.formatDate(clock.date, "ddd dd MMM").toUpperCase()
    color: root.pinned ? Theme.accent : (root.hovered ? Theme.accent : Theme.text)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
    font.bold: true

    Behavior on color {
      ColorAnimation { duration: 200; easing.type: Easing.InOutSine }
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Theme.stripe
    visible: root.hovered || root.pinned
    color: Theme.accent
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
