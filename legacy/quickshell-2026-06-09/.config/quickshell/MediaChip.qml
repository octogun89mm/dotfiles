import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitWidth: Math.min(240, mediaLabel.implicitWidth + Theme.padMd * 2)
  implicitHeight: Theme.chipHeight
  visible: MediaState.available

  Text {
    id: mediaLabel
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padMd
    anchors.right: parent.right
    anchors.rightMargin: Theme.padMd
    text: MediaState.displayText
    elide: Text.ElideRight
    color: MediaState.playing ? Theme.text : Theme.textDim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
  }

  MouseArea {
    anchors.fill: parent
    onClicked: MediaState.playPause()
  }
}
