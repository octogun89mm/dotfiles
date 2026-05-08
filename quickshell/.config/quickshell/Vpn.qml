import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: false
  property color activeColor: Theme.success
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenActive || VpnState.connected
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    text: VpnState.icon
    color: VpnState.connected ? root.activeColor : root.inactiveColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    onClicked: VpnState.toggle()
  }
}
