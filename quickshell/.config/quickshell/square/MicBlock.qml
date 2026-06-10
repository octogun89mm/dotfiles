import QtQuick

// Mic-in-use indicator. Only shown (by parent Block) while hot, critical color.
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: label.implicitWidth

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    text: "󰍬"
    color: Theme.critical
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontLg
  }
}
