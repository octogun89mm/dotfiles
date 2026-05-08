import QtQuick

Rectangle {
  id: root

  property bool onlyWhenDisabled: true
  property color activeColor: Theme.warning
  property color inactiveColor: Theme.textDim

  visible: !onlyWhenDisabled || !SuspendState.enabled
  color: "transparent"
  implicitWidth: indicator.implicitWidth + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.padSm
    text: SuspendState.icon
    color: SuspendState.enabled ? root.inactiveColor : root.activeColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    onClicked: SuspendState.toggle()
  }
}
