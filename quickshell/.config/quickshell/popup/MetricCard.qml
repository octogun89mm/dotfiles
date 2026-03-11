import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property string title: ""
  property string value: ""
  property string detail: ""
  property string detail2: ""

  color: Wallust.base01
  implicitWidth: 240
  implicitHeight: 62 + (detail !== "" ? 18 : 0) + (detail2 !== "" ? 18 : 0)

  Column {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 6

    Text {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      color: Wallust.base04
      font.family: "Roboto Mono"
      font.pixelSize: 10
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.value
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Roboto Mono"
      font.pixelSize: 13
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.detail
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Roboto Mono"
      font.pixelSize: 10
      visible: text !== ""
    }

    Text {
      width: parent.width
      text: root.detail2
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Roboto Mono"
      font.pixelSize: 10
      visible: text !== ""
    }
  }
}
