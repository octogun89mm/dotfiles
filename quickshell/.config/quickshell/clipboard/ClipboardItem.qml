import QtQuick
import "../wallust.js" as Wallust
import "." as Clipboard

Rectangle {
  id: root

  required property int sourceIndex
  required property string preview
  required property bool isImage
  required property string imagePath
  property bool selected: false

  property bool hovered: hoverArea.containsMouse

  color: Wallust.base01
  border.width: 2
  border.color: (selected || hovered) ? Wallust.accent : Wallust.base03
  implicitHeight: content.implicitHeight + 20
  height: implicitHeight

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: Clipboard.ClipboardState.select(root.sourceIndex)
  }

  Column {
    id: content
    anchors.fill: parent
    anchors.margins: 10
    anchors.rightMargin: 32
    spacing: 8

    Image {
      width: parent.width
      height: 120
      visible: root.isImage && root.imagePath !== ""
      source: root.imagePath !== "" ? ("file://" + root.imagePath) : ""
      fillMode: Image.PreserveAspectFit
      asynchronous: true
    }

    Text {
      width: parent.width
      text: root.preview
      color: root.isImage ? Wallust.base04 : Wallust.base05
      font.family: "Iosevka"
      font.pixelSize: 11
      wrapMode: Text.Wrap
      maximumLineCount: root.isImage ? 1 : 3
      elide: Text.ElideRight
    }
  }

  Rectangle {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 8
    anchors.rightMargin: 8
    width: 18
    height: 18
    visible: root.hovered
    color: "transparent"
    border.width: 2
    border.color: Wallust.base03

    Text {
      anchors.centerIn: parent
      text: "󰅖"
      color: Wallust.base05
      font.family: "Symbols Nerd Font Mono"
      font.pixelSize: 10
    }

    MouseArea {
      anchors.fill: parent
      onClicked: Clipboard.ClipboardState.deleteEntry(root.sourceIndex)
    }
  }
}
