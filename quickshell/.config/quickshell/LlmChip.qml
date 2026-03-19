import QtQuick
import "wallust.js" as Wallust

Rectangle {
  color: "transparent"
  border.width: 2
  border.color: Wallust.accent
  implicitWidth: llmLabel.implicitWidth + 18
  implicitHeight: 24
  visible: LlmState.active

  Text {
    id: llmLabel
    anchors.centerIn: parent
    text: LlmState.modelAlias + " :" + LlmState.port
    color: Wallust.base05
    font.family: "Roboto Mono"
    font.pixelSize: 11
    font.bold: true
  }
}
