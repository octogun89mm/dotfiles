import QtQuick
import "wallust.js" as Wallust

Rectangle {
  id: root

  color: "transparent"
  border.width: 2
  border.color: MediaState.playing ? Wallust.accent : Wallust.base03
  implicitWidth: mediaLabel.implicitWidth + 18
  implicitHeight: 24
  visible: MediaState.available

  Text {
    id: mediaLabel
    anchors.centerIn: parent
    width: Math.min(260, implicitWidth)
    text: MediaState.displayText
    elide: Text.ElideRight
    color: MediaState.playing ? Wallust.base05 : Wallust.base03
    font.family: "Iosevka"
    font.pixelSize: 11
    font.bold: true
  }

  MouseArea {
    anchors.fill: parent
    onClicked: MediaState.playPause()
  }
}
