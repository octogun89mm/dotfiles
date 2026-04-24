import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property string title: ""
  property string value: ""
  property string detail: ""
  property string detail2: ""
  property var graphs: []

  color: Wallust.base00
  implicitWidth: 240

  Column {
    id: textCol
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 12
    spacing: 4

    Text {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      color: Wallust.base04
      font.family: "Iosevka"
      font.pixelSize: 10
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.value
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Iosevka"
      font.pixelSize: 13
      font.bold: true
    }

    Text {
      width: parent.width
      text: root.detail
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Iosevka"
      font.pixelSize: 10
      visible: text !== ""
    }

    Text {
      width: parent.width
      text: root.detail2
      elide: Text.ElideRight
      color: Wallust.base05
      font.family: "Iosevka"
      font.pixelSize: 10
      visible: text !== ""
    }
  }

  Column {
    id: graphCol
    anchors.top: textCol.bottom
    anchors.topMargin: root.graphs.length > 0 ? 4 : 0
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    anchors.bottomMargin: root.graphs.length > 0 ? 8 : 0
    spacing: 2
    visible: root.graphs.length > 0

    Repeater {
      model: root.graphs.length

      MiniGraph {
        required property int index
        width: graphCol.width
        height: Math.max(10, (graphCol.height - (root.graphs.length - 1) * graphCol.spacing) / root.graphs.length)
        values: root.graphs[index].values || []
        graphColor: root.graphs[index].color || Wallust.base0C
        label: root.graphs[index].label || ""
        maxValue: root.graphs[index].maxValue !== undefined ? root.graphs[index].maxValue : 100
      }
    }
  }
}
