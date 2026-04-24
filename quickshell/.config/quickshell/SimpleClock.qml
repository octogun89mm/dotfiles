import QtQuick
import Quickshell
import "wallust.js" as Wallust

Item {
  id: root

  property bool hovered: clockMouse.containsMouse
  property bool pinned: false

  signal clicked

  implicitWidth: clockLabel.implicitWidth + 16
  implicitHeight: 20

  Rectangle {
    id: pinBox
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height
    width: root.pinned ? parent.width : 0
    color: Wallust.base08

    Behavior on width {
      NumberAnimation {
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.6
      }
    }
  }

  Text {
    id: clockLabel
    anchors.centerIn: parent
    text: Qt.formatTime(clock.date, "hh:mm AP")
    color: root.pinned ? Wallust.background : Wallust.base05
    font.family: "Iosevka"
    font.pixelSize: 14
    font.bold: true

    Behavior on color {
      ColorAnimation { duration: 320; easing.type: Easing.InOutSine }
    }
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
