import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd + Theme.stripe
  implicitHeight: Theme.chipHeight

  Rectangle {
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: Theme.stripe
    color: Theme.accentAlt
  }

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.stripe + Theme.padSm
    text: LanguageState.layout
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    font.letterSpacing: 0.5
  }
}
