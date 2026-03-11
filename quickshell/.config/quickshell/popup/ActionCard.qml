import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string value: ""
  property bool highlighted: false

  signal clicked

  color: highlighted ? Wallust.base0D : Wallust.base03
  implicitWidth: 132
  implicitHeight: 54

  Row {
    id: content
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 8
    anchors.bottomMargin: 8
    spacing: 10

    Text {
      width: 18
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignHCenter
      text: root.icon
      color: highlighted ? Wallust.base00 : Wallust.base05
      font.family: "Symbols Nerd Font Mono"
      font.pixelSize: 16
    }

    Column {
      width: parent.width - 18 - parent.spacing
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Text {
        text: root.title
        width: parent.width
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? Wallust.base00 : Wallust.base04
        font.family: "Roboto Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Text {
        text: root.value
        width: parent.width
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? Wallust.base00 : Wallust.base05
        font.family: "Roboto Mono"
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.clicked()
  }
}
