import QtQuick

// 2-letter keyboard layout code.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: KeyboardState.layout
    color: Theme.accentAlt
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSm
    font.bold: true
    font.letterSpacing: 0.5
  }
}
