import QtQuick

Rectangle {
  id: root

  property bool onlyWhenDisabled: true
  property color activeColor: Theme.warning
  property color inactiveColor: Theme.textDim

  readonly property bool shouldShow: !onlyWhenDisabled || !SuspendState.enabled

  visible: shouldShow
  color: "transparent"
  implicitWidth: Theme.fontSmall + 3 + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: SuspendState.icon
    color: SuspendState.enabled ? root.inactiveColor : root.activeColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.shouldShow
    onClicked: SuspendState.toggle()
  }
}
