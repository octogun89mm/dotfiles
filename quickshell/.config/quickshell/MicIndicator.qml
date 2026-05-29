import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.critical
  property color inactiveColor: Theme.textDim

  readonly property bool shouldShow: !onlyWhenActive || MicState.active

  visible: shouldShow
  color: "transparent"
  implicitWidth: Theme.fontSmall + 3 + Theme.padMd
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
    enabled: root.shouldShow
    hoverEnabled: true
  }
}
