import QtQuick
import Quickshell

Item {
  id: root

  property bool hovered: clockMouse.containsMouse
  property bool pinned: false

  signal clicked

  implicitWidth: clockLabel.implicitWidth + Theme.padMd * 2
  implicitHeight: Theme.chipHeight

  Rectangle {
    visible: root.pinned
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    height: Theme.stripe
    color: Theme.accent
  }

  Text {
    id: clockLabel
    anchors.centerIn: parent
    text: Qt.formatTime(clock.date, "hh:mm AP")
    color: root.pinned ? Theme.accent : (root.hovered ? Theme.accent : Theme.text)
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontTitle
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
    id: clockMouse
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
