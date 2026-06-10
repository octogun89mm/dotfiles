import QtQuick
import "../wallust.js" as Wallust

Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string value: ""
  property bool highlighted: false
  readonly property color highlightBg: Wallust.base0C
  readonly property color highlightFg: (0.299 * highlightBg.r + 0.587 * highlightBg.g + 0.114 * highlightBg.b) > 0.5 ? Wallust.base00 : Wallust.base06

  signal clicked

  color: highlighted ? highlightBg : Wallust.base00
  implicitWidth: 132
  implicitHeight: 54

  Row {
    id: content
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    anchors.topMargin: 8
    anchors.bottomMargin: 8
    spacing: 6

    Text {
      width: 18
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignHCenter
      text: root.icon
      color: highlighted ? root.highlightFg : Wallust.base05
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
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 8
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? root.highlightFg : Wallust.base04
        font.family: "Liberation Mono"
        font.pixelSize: 10
        font.bold: true
      }

      Text {
        text: root.value
        width: parent.width
        elide: Text.ElideRight
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 8
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? root.highlightFg : Wallust.base05
        font.family: "Liberation Mono"
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
