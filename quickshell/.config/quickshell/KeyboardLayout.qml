import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd * 2
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: LanguageState.layout
    color: Theme.accentAlt
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    font.letterSpacing: 0.5
  }
}
