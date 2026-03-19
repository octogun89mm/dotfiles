import QtQuick
import "wallust.js" as Wallust

Rectangle {
  color: "transparent"
  border.width: 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + 10
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: LlmState.icon
    color: LlmState.active ? Wallust.accent : Wallust.base03
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent

    onClicked: LlmState.toggle()
  }
}
