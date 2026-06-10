import QtQuick

// Compact swaybar-style monitor badge: solid accent fill, bg-coloured number.
Rectangle {
  id: root

  required property int screenIndex
  required property color accentColor

  implicitWidth: label.implicitWidth + Theme.padMd * 2
  implicitHeight: Theme.barHeight
  radius: 0
  color: root.accentColor

  Text {
    id: label
    anchors.centerIn: parent
    text: String(root.screenIndex + 1)
    color: Theme.bg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd
    font.bold: true
  }
}
