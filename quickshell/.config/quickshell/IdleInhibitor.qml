import QtQuick

Rectangle {
  id: root

  property bool onlyWhenActive: true
  property color activeColor: Theme.warning
  property color inactiveColor: Theme.textDim

  readonly property bool shouldShow: !onlyWhenActive || IdleState.active

  visible: shouldShow
  color: "transparent"
  implicitWidth: Theme.fontSmall + 3 + Theme.padMd
  implicitHeight: Theme.chipHeight

  Text {
    id: indicator
    anchors.centerIn: parent
    text: IdleState.icon
    color: IdleState.active ? root.activeColor : root.inactiveColor
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fontSmall + 3
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.shouldShow
    onClicked: IdleState.toggle()
  }
}
