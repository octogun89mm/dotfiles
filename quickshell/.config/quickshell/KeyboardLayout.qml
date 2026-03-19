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
    text: LanguageState.layout
    color: Wallust.accent
    font.family: "Roboto Mono"
    font.pixelSize: 12
    font.bold: true
  }
}
