import QtQuick
import "wallust.js" as Wallust

Rectangle {
  id: root

  property bool borderless: false
  property bool onlyWhenActive: false
  property color activeColor: Wallust.accent
  property color inactiveColor: Wallust.base03

  visible: !onlyWhenActive || IdleState.active
  color: "transparent"
  border.width: borderless ? 0 : 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + (borderless ? 0 : 10)
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: IdleState.icon
    color: IdleState.active ? root.activeColor : root.inactiveColor
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent

    onClicked: IdleState.toggle()
  }
}
