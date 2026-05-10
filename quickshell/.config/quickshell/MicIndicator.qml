import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.critical
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenActive || MicState.active
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padSm
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: MicState.active ? "󰍬" : "󰍭"
    color: MicState.active ? root.activeColor : root.inactiveColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
  }
}
