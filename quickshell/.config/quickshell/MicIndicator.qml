import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.critical
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenActive || MicState.active
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd + Theme.stripe
  implicitHeight: Theme.chipHeight

  Rectangle {
    visible: MicState.active
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: Theme.stripe
    color: root.activeColor
  }

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.stripe + Theme.padSm
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
