import QtQuick
import "wallust.js" as Wallust

Rectangle {
  id: root

  color: "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: VolumeState.volume.toString().padStart(2, "0")
    color: VolumeState.muted ? Wallust.base03 : Wallust.accent
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        VolumeState.toggleMute()
      } else if (mouse.button === Qt.RightButton) {
        VolumeState.switchSink()
      }
    }

    onWheel: wheel => {
      const step = 5
      let target = VolumeState.volume
      if (wheel.angleDelta.y > 0) {
        target = Math.min(target + step, 99)
      } else if (wheel.angleDelta.y < 0) {
        target = Math.max(target - step, 0)
      }
      VolumeState.setVolume(target)
    }
  }
}
