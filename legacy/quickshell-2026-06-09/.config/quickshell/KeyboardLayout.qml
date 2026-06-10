import QtQuick

Rectangle {
  id: root

  color: "transparent"
  implicitWidth: layoutMetrics.width + Theme.padMd * 2
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: LanguageState.layout
    width: layoutMetrics.width
    horizontalAlignment: Text.AlignHCenter
    color: Theme.accentAlt
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    font.letterSpacing: 0.5
  }

  TextMetrics {
    id: layoutMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
    font.letterSpacing: 0.5
    text: "MMMM"
  }
}
