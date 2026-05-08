import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.warning
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenActive || IdleState.active
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    text: IdleState.icon
    color: IdleState.active ? root.activeColor : root.inactiveColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    onClicked: IdleState.toggle()
  }
}
