import QtQuick
import "wallust.js" as Wallust

Rectangle {
  id: root

  property bool borderless: false
  property bool onlyWhenActive: false
  property color activeColor: Wallust.accent
  property color inactiveColor: Wallust.base03

  visible: !onlyWhenActive || VpnState.connected
  color: "transparent"
  border.width: borderless ? 0 : 2
  border.color: Wallust.base03
  implicitWidth: indicator.implicitWidth + (borderless ? 0 : 10)
  implicitHeight: 24

  Text {
    id: indicator
    anchors.centerIn: parent
    text: VpnState.icon
    color: VpnState.connected ? root.activeColor : root.inactiveColor
    font.family: "Symbols Nerd Font Mono"
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent
    onClicked: VpnState.toggle()
  }
}
